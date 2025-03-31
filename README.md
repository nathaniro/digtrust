# User Identity Smart Contract

## Overview
The `user_identity` smart contract is designed for managing user authentication and identity verification in a decentralized system. It provides role-based access control, verification requests, and metadata updates for registered users.

## Features
- **User Registration**: Users can register with a unique decentralized identity (DID) and role.
- **Role-Based Access Control**: Defines multiple roles such as Patient, Doctor, Researcher, and Admin.
- **Identity Verification**: Allows administrators to verify users.
- **Permission Management**: Controls user capabilities based on their roles.
- **Metadata Updates**: Users can update their identity metadata.
- **Verification Requests**: Users can request verification and track status.
- **Read-Only Access**: Allows retrieval of user identities, verification status, and role permissions.

## Roles
- **Patient (`ROLE-PATIENT`)**: Basic user with limited permissions.
- **Doctor (`ROLE-DOCTOR`)**: Can access anonymized data.
- **Researcher (`ROLE-RESEARCHER`)**: Similar permissions to doctors.
- **Admin (`ROLE-ADMIN`)**: Full control, can verify identities and update permissions.

## Constants
- `err-owner-only (u100)`: Only the contract owner can perform the action.
- `err-unauthorized (u101)`: Unauthorized access.
- `err-already-registered (u102)`: User already registered.
- `err-not-found (u103)`: User not found.
- `err-invalid-role (u104)`: Invalid role selection.

## Data Structures
- `user-identities`: Stores user details including DID, role, verification status, and metadata.
- `role-permissions`: Maps roles to their respective permissions.
- `verification-requests`: Stores pending verification requests.

## Functions
### Public Functions
- `register-identity(did, role, metadata)`: Registers a new user identity.
- `submit-verification-request(proof-document)`: Submits a verification request.
- `verify-identity(user)`: Admin function to verify a user.
- `update-metadata(new-metadata)`: Updates user metadata.

### Read-Only Functions
- `has-permission(user, permission-key)`: Checks if a user has a specific permission.
- `get-identity(user)`: Retrieves user identity details.
- `get-verification-request(user)`: Retrieves the verification request status.
- `is-verified(user)`: Checks if a user is verified.
- `get-role-permissions(role)`: Retrieves permissions associated with a role.

## Security & Access Control
- Only registered users can update metadata or submit verification requests.
- Only admins can verify identities.
- Role-based permissions ensure proper access control.

## Usage
1. **Register a user**: Call `register-identity` with DID, role, and metadata.
2. **Request verification**: Call `submit-verification-request` with a proof document.
3. **Admin verifies identity**: Call `verify-identity` to approve verification.
4. **Check verification status**: Use `is-verified` or `get-verification-request`.

## License
This smart contract is open-source and free to use under the MIT License.

