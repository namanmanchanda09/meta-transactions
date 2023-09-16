// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "../src/Relayer.sol";
import "../src/MinimalBAYC.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MinimalBAYCTest is Test {

    MinimalBAYC public bayc; 

    // relayer or forwarder
    Relayer public relayer;

    // alice - original sender (signs the message)
    address public alice;

    // bob - executes the transaction on behalf of alice
    address public bob;

    bytes32 private constant _TYPEHASH =
        keccak256("ForwardRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data)");

    function setUp() public {
        relayer = new Relayer();
        bayc = new MinimalBAYC("MinimalBAYC", "BAYC", 1000, address(relayer));
        alice = vm.addr(42);
    }

    /**
        calls the (execute fn of Relayer) which eventually calls the (mintTo fn of MinimalBAYC) to mint token
     */
    function testExecute() public {
        vm.pauseGasMetering();

        // the calldata that has to be called in the BAYC contract
        bytes memory dataField = abi.encodeWithSignature("mintTo(uint256)", 5);

        // creating the Relayer's ForwardRequest structure
        Relayer.ForwardRequest memory req = Relayer.ForwardRequest({
            from: alice,
            to: address(bayc),
            value: 0.05 ether,
            gas: 1000,
            nonce: 0,
            data: dataField
        });

        // creating the hashed typed data
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(_TYPEHASH, req.from, req.to, req.value, req.gas, req.nonce, keccak256(req.data)))
        );


        // signing the hashed data using alice's private key
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(42, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        // bob making the transaction on-behalf-of alice
        vm.deal(bob, 100 ether);
        vm.startPrank(bob);
        relayer.execute{value: 0.05 ether, gas: 100000000}(req, signature);

        // Asserting if alice has received the token
        address ownerOfTokenId = bayc.ownerOf(1);
        assertEq(alice, ownerOfTokenId);
    }

    /**
        Helper Functions
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparator(), structHash);
    }

    function _domainSeparator() internal pure returns (bytes32) {
        return keccak256(abi.encode("Testing EIP712"));
    }
}


