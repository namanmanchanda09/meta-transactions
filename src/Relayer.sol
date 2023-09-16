// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
    Implements EIP712 for structed Data Hashing
 */
contract Relayer {
    using ECDSA for bytes32;

    mapping(address => uint256) private _nonces;

    // structure of incoming request
    struct ForwardRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        bytes data;
    }

    bytes32 private constant _TYPEHASH =
        keccak256("ForwardRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data)");

    // DOMAIN_SEPARATOR
    bytes32 public constant DOMAIN_SEPARATOR = keccak256(abi.encode("Testing EIP712"));

    function getNonce(address from) public view returns (uint256) {
        return _nonces[from];
    }

    // function to verify if the signature is signed by the sender itself
    function verify(ForwardRequest memory req, bytes calldata signature) public view returns (bool) {
        address signer = _hashTypedDataV4(
            keccak256(abi.encode(_TYPEHASH, req.from, req.to, req.value, req.gas, req.nonce, keccak256(req.data)))
        ).recover(signature);
        return _nonces[req.from] == req.nonce && signer == req.from;
    }

    // function to forward the incoming transaction request to the MinimalBAYC contract
    function execute(ForwardRequest calldata req, bytes calldata signature)
        public
        payable
        returns (bool, bytes memory)
    {
        require(verify(req, signature), "Relayer: signature does not match request");
        _nonces[req.from] = req.nonce + 1;

        (bool success, bytes memory returndata) =
            req.to.call{gas: req.gas, value: req.value}(abi.encodePacked(req.data, req.from));
        if (gasleft() <= req.gas / 63) {
            assembly {
                invalid()
            }
        }

        return (success, returndata);
    }
    
    // Helper Function
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(DOMAIN_SEPARATOR, structHash);
    }
}
