# Medical Records Management System

The Medical Records Management System (MRMS) is a blockchain-based application designed to securely manage and control access to medical records using smart contract technology. This system utilizes Clarity, a predictable and safe smart contract language developed by Blockstack, tailored to handle sensitive and crucial data securely and efficiently.

## Features

1. **Immutable Medical Records**: Securely store medical records in an immutable format, ensuring the integrity and accuracy of patient data.

2. **Dynamic Access Control**: Patients can grant or revoke access to their medical records to healthcare providers on a permission basis, including setting time-limited access.

3. **Audit Trails**: Automatically maintain a detailed log of all actions performed on the records, including access and modifications, enhancing transparency and accountability.

4. **Encrypted Data Storage**: All medical records are stored in an encrypted format, ensuring that sensitive information remains confidential and secure against unauthorized access.

## System Requirements

- **Blockstack Node**: The smart contract needs to be deployed on a Stacks blockchain node.
- **Clarity**: Familiarity with the Clarity language is required to interact with or modify the smart contract.
- **Cryptography Tools**: Tools to encrypt and decrypt data before it is sent to or retrieved from the blockchain.

## Installation Guide

To set up the Medical Records Management System:

### Step 1: Set Up Your Environment

Ensure you have a Blockstack node set up. Follow the [official Blockstack documentation](https://docs.stacks.co/) for guidance on setting up a node.

### Step 2: Deploy the Smart Contract

1. Clone this repository to your local machine.
2. Navigate to the directory containing the smart contract files.
3. Deploy the contract to your Blockstack node using the appropriate command-line tools provided by Blockstack.

   ```bash
   # Example command
   clarity-cli deploy /path/to/medical-records-management.clar /path/to/output.tx
   ```

### Step 3: Verify the Deployment

Check the deployment status through your Blockstack node dashboard or CLI to ensure the contract is active and correctly deployed.

## Usage

### Creating Medical Records

To create a medical record, the patient needs to call the `create-medical-record` function with a unique record ID and encrypted content.

```bash
clarity-cli call /address/medical-records-management.clar create-medical-record '{"record-id": 123, "encrypted-content": "encrypted_data_here"}'
```

### Granting Access

To grant access to a healthcare provider, use the `grant-record-access` function with the record ID, user principal of the healthcare provider, and optional expiry block height for time-limited access.

```bash
clarity-cli call /address/medical-records-management.clar grant-record-access '{"record-id": 123, "user": "SP2H1234...ABCDEFG", "expiry": 50000}'
```

### Revoking Access

To revoke access, use the `revoke-record-access` function specifying the record ID and the user principal.

```bash
clarity-cli call /address/medical-records-management.clar revoke-record-access '{"record-id": 123, "user": "SP2H1234...ABCDEFG"}'
```

### Accessing Medical Records

Authorized users can access records by calling the `access-medical-record` function with the appropriate record ID.

```bash
clarity-cli call /address/medical-records-management.clar access-medical-record '{"record-id": 123}'
```

## Contributing

Contributions to the MRMS are welcome. Please follow the standard fork, branch, and pull request workflow to propose changes.

## Security

This smart contract has been developed with an emphasis on security and compliance with applicable health data management regulations. However, users are encouraged to perform their security audits and compliance checks according to their local jurisdiction's laws and needs.