# Reputation Token (RT) Smart Contract

## Overview
The **Reputation Token (RT)** is a **non-transferable, reputation-based fungible token** designed to reward users based on their **job performance, value, difficulty, and client ratings**. It follows the **SIP-010 fungible token standard** while restricting direct transfers to maintain its integrity as a reputation-based metric.

## Features
- **Minting:** Users earn RT tokens based on job completion, job value, difficulty, and client ratings.
- **Burning:** RT tokens can be burned as penalties for poor performance.
- **Freezing:** Tokens can be temporarily frozen to restrict usage.
- **Non-Transferable:** Users cannot transfer RT tokens freely; they are managed by the contract owner.
- **Job History Tracking:** Maintains a history of completed jobs, total job value, and average client rating.

## Functions

### SIP-010 Standard Functions
- `get-name` → Returns the token name (**Reputation Token**).
- `get-symbol` → Returns the token symbol (**RT**).
- `get-decimals` → Returns the token decimal precision (**6 decimals**).
- `get-balance(account)` → Returns the balance of RT tokens for a given user.
- `get-total-supply` → Returns the total supply of RT tokens.
- `get-token-uri` → Returns **none** (no token metadata provided).

### Reputation-Specific Functions
#### **Minting Reputation Tokens**
- `mint-reputation-tokens(recipient, job-value, job-difficulty, client-rating)`
  - **Requires contract owner authorization.**
  - Calculates tokens to mint based on:
    - Job value
    - Job difficulty
    - Client rating
  - Updates user’s job history.
  - Mints and assigns RT tokens to the recipient.

#### **Burning Reputation Tokens**
- `burn-reputation-tokens(user, amount)`
  - **Requires contract owner authorization.**
  - Reduces the reputation tokens of a user as a penalty.

#### **Freezing Reputation Tokens**
- `freeze-reputation-tokens(user, amount)`
  - **Requires contract owner authorization.**
  - Transfers a specified amount of RT tokens to the contract owner, effectively freezing them.

#### **Preventing Unauthorized Transfers**
- `transfer(amount, sender, recipient, memo)`
  - **Always fails with an error (`err-transfer-not-allowed`).**
  - Prevents direct transfer of RT tokens to ensure reputation integrity.

#### **Retrieving User Job History**
- `get-user-job-history(user)`
  - Returns a user’s job history including:
    - **Completed jobs**
    - **Total value of jobs**
    - **Average rating from clients**

## Security & Access Control
- Only the **contract owner** can mint, burn, or freeze reputation tokens.
- RT tokens **cannot be transferred** between users.
- Reputation data is **stored on-chain**, ensuring transparency and security.

## Usage Scenarios
- **Freelance Platforms:** Rewarding workers based on job difficulty, value, and client satisfaction.
- **Reputation Systems:** Maintaining a trust-based economy where users earn credibility over time.
- **Decentralized Work Networks:** Preventing fake reputations by ensuring tokens are only issued for real work.

## Future Enhancements
- Implement **automated penalties** for fraud detection.
- Introduce **tiered reputation rewards** for consistent high performers.
- Enable **on-chain dispute resolution mechanisms** for rating adjustments.

---
This contract ensures that **Reputation Tokens are a true measure of a user’s credibility** by linking them to real work and client feedback while preventing manipulation through transfers. 🚀