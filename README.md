# StackFundMe - Milestone-Based Crowdfunding Smart Contract

A decentralized crowdfunding platform built on Stacks blockchain that enables milestone-based fundraising campaigns with built-in accountability.

## Features

- 🚀 Create customizable fundraising campaigns
- 🎯 Set multiple milestones for fund release
- 💰 Secure contribution management
- ✅ Milestone approval system
- 🔄 Automatic refund mechanism
- 📊 Transparent campaign tracking

## Smart Contract Functions

### Campaign Management

```clarity
(create-campaign (goal uint) (deadline uint) (total-milestones uint))
(set-milestone (campaign-id uint) (milestone-id uint) (desc (buff 100)) (amount uint))
```

### Contribution Handling

```clarity
(contribute (campaign-id uint) (amount uint))
(request-refund (campaign-id uint))
```

### Milestone Operations

```clarity
(approve-milestone (campaign-id uint) (milestone-id uint))
(withdraw-milestone (campaign-id uint) (milestone-id uint))
```

### Read-Only Functions

```clarity
(get-campaign (campaign-id uint))
(get-milestone (campaign-id uint) (milestone-id uint))
(get-contribution (campaign-id uint) (backer principal))
(get-next-campaign-id)
```

## Error Codes

| Code | Description |
|------|-------------|
| `u100` | Unauthorized access |
| `u101` | Resource not found |
| `u102` | Resource already exists |
| `u103` | Campaign inactive |
| `u104` | Deadline passed |
| `u105` | Too early for action |
| `u106` | Invalid milestone |
| `u107` | Goal not met |
| `u108` | Already approved |
| `u109` | Insufficient funds |
| `u110` | Not a contributor |

## Usage Example

1. Create a new campaign:
```clarity
(contract-call? .stackfundme create-campaign u1000000 u100 u3)
```

2. Set campaign milestones:
```clarity
(contract-call? .stackfundme set-milestone u1 u1 0x4D696C6573746F6E65203100000000 u300000)
```

3. Contribute to a campaign:
```clarity
(contract-call? .stackfundme contribute u1 u50000)
```

## Security Considerations

- Campaign funds are held in the contract until milestone approval
- Only campaign creators can approve milestones
- Automatic refunds if campaign goal isn't met
- Time-locked operations based on block height
- Principal-based authorization checks



### Testing

```bash
clarinet test
```
