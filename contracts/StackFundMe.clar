;; ------------------------------------------------------------
;; StackFundMe - Milestone-Based Crowdfunding on Stacks
;; Language: Clarity
;; Author: ChatGPT
;; License: MIT
;; ------------------------------------------------------------

(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_EXISTS (err u102))
(define-constant ERR_INACTIVE (err u103))
(define-constant ERR_TOO_LATE (err u104))
(define-constant ERR_TOO_EARLY (err u105))
(define-constant ERR_INVALID_MILESTONE (err u106))
(define-constant ERR_GOAL_NOT_MET (err u107))
(define-constant ERR_ALREADY_APPROVED (err u108))
(define-constant ERR_INSUFFICIENT_FUNDS (err u109))
(define-constant ERR_NOT_CONTRIBUTOR (err u110))

(define-data-var next-campaign-id uint u1)

(define-map campaigns
  uint
  {
    creator: principal,
    goal: uint,
    raised: uint,
    deadline: uint,
    current-milestone: uint,
    total-milestones: uint,
    is-active: bool
  }
)

(define-map milestones
{campaign-id: uint, milestone-id: uint}
  {
    description: (buff 100),
    amount: uint,
    approved: bool
  }
)

(define-map contributions
  {campaign-id: uint, backer: principal}
  uint
)

;; ------------------------------------------------------------
;; FUNCTION: create-campaign
(define-public (create-campaign (goal uint) (deadline uint) (total-milestones uint))
  (let (
    (id (var-get next-campaign-id))
  )
    (begin
      (map-set campaigns
        id
        {
          creator: tx-sender,
          goal: goal,
          raised: u0,
          deadline: deadline,
          current-milestone: u0,
          total-milestones: total-milestones,
          is-active: true
        }
      )
      (var-set next-campaign-id (+ id u1))
      (ok id)
    )
  )
)

;; ------------------------------------------------------------
;; FUNCTION: set-milestone
(define-public (set-milestone (campaign-id uint) (milestone-id uint) (desc (buff 100)) (amount uint))
  (let (
    (campaign (map-get? campaigns campaign-id))
  )
    (match campaign
      campaign-data
        (if (is-eq (get creator campaign-data) tx-sender)
            (begin
              (map-set milestones
                {campaign-id: campaign-id, milestone-id: milestone-id}
                {
                  description: desc,
                  amount: amount,
                  approved: false
                }
              )
              (ok true)
            )
            ERR_UNAUTHORIZED
        )
      ERR_NOT_FOUND
    )
  )
)

;; ------------------------------------------------------------
;; FUNCTION: contribute
(define-public (contribute (campaign-id uint) (amount uint))
  (let (
    (campaign (map-get? campaigns campaign-id))
  )
    (match campaign
      campaign-data
        (if (and (get is-active campaign-data) (<= stacks-block-height (get deadline campaign-data)))
            (begin
              (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
              (map-set contributions
                {campaign-id: campaign-id, backer: tx-sender}
                (+ (default-to u0 (map-get? contributions {campaign-id: campaign-id, backer: tx-sender})) amount)
              )
              (map-set campaigns
                campaign-id
                (merge campaign-data { raised: (+ (get raised campaign-data) amount) })
              )
              (ok true)
            )
            ERR_TOO_LATE
        )
      ERR_NOT_FOUND
    )
  )
)

;; ------------------------------------------------------------
;; FUNCTION: approve-milestone
(define-public (approve-milestone (campaign-id uint) (milestone-id uint))
  (let (
    (campaign (map-get? campaigns campaign-id))
    (milestone (map-get? milestones {campaign-id: campaign-id, milestone-id: milestone-id}))
  )
    (match campaign
      campaign-data
        (if (is-eq (get creator campaign-data) tx-sender)
            (match milestone
              milestone-data
                (if (not (get approved milestone-data))
                    (begin
                      (map-set milestones
                        {campaign-id: campaign-id, milestone-id: milestone-id}
                        (merge milestone-data { approved: true })
                      )
                      (ok true)
                    )
                    ERR_ALREADY_APPROVED
                )
              ERR_NOT_FOUND
            )
            ERR_UNAUTHORIZED
        )
      ERR_NOT_FOUND
    )
  )
)

;; ------------------------------------------------------------
;; FUNCTION: withdraw-milestone
(define-public (withdraw-milestone (campaign-id uint) (milestone-id uint))
  (let (
    (campaign (map-get? campaigns campaign-id))
    (milestone (map-get? milestones {campaign-id: campaign-id, milestone-id: milestone-id}))
  )
    (match campaign
      campaign-data
        (if (is-eq (get creator campaign-data) tx-sender)
            (match milestone
              milestone-data
                (if (get approved milestone-data)
                    (begin
                      (try! (as-contract (stx-transfer? (get amount milestone-data) tx-sender (get creator campaign-data))))
                      (ok true)
                    )
                    ERR_INVALID_MILESTONE
                )
              ERR_NOT_FOUND
            )
            ERR_UNAUTHORIZED
        )
      ERR_NOT_FOUND
    )
  )
)

;; ------------------------------------------------------------
;; FUNCTION: request-refund
(define-public (request-refund (campaign-id uint))
  (let (
    (campaign (map-get? campaigns campaign-id))
    (user-contribution (map-get? contributions {campaign-id: campaign-id, backer: tx-sender}))
  )
    (match campaign
      campaign-data
        (if (and (> stacks-block-height (get deadline campaign-data)) (< (get raised campaign-data) (get goal campaign-data)))
            (match user-contribution
              amount
                (begin
                  (map-delete contributions {campaign-id: campaign-id, backer: tx-sender})
                  (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
                  (ok true)
                )
              ERR_NOT_CONTRIBUTOR
            )
            ERR_GOAL_NOT_MET
        )
      ERR_NOT_FOUND
    )
  )
)

;; ------------------------------------------------------------
;; READ-ONLY FUNCTIONS
;; ------------------------------------------------------------

;; Get campaign details
(define-read-only (get-campaign (campaign-id uint))
  (map-get? campaigns campaign-id)
)

;; Get milestone details
(define-read-only (get-milestone (campaign-id uint) (milestone-id uint))
  (map-get? milestones {campaign-id: campaign-id, milestone-id: milestone-id})
)

;; Get user contribution
(define-read-only (get-contribution (campaign-id uint) (backer principal))
  (map-get? contributions {campaign-id: campaign-id, backer: backer})
)

;; Get next campaign ID
(define-read-only (get-next-campaign-id)
  (var-get next-campaign-id)
)