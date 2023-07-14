// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {INonfungiblePositionManager as INPM, IERC721Permit, IPeripheryImmutableState} from "./interfaces/INonfungiblePositionManager.sol";

// details about the uniswap position
struct PositionFull {
    // the nonce for permits
    uint96 nonce;
    // the address that is approved for spending this token
    address operator;
    address token0;
    address token1;
    // The pool's fee in hundredths of a bip, i.e. 1e-6
    uint24 fee;
    // the tick range of the position
    int24 tickLower;
    int24 tickUpper;
    // the liquidity of the position
    uint128 liquidity;
    // the fee growth of the aggregate position as of the last action on the individual position
    uint256 feeGrowthInside0LastX128;
    uint256 feeGrowthInside1LastX128;
    // how many uncollected tokens are owed to the position, as of the last computation
    uint128 tokensOwed0;
    uint128 tokensOwed1;
}

struct Position {
    address token0;
    address token1;
    // The pool's fee in hundredths of a bip, i.e. 1e-6
    uint24 fee;
    // the tick range of the position
    int24 tickLower;
    int24 tickUpper;
    // the liquidity of the position
    uint128 liquidity;
}

/// @title Uniswap v3 Nonfungible Position Manager Caller
/// @author Aperture Finance
/// @notice Gas efficient library to call `INonfungiblePositionManager` assuming it exists.
/// @dev Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// However, this is safe because "Note that you do not need to update the free memory pointer if there is no following
/// allocation, but you can only use memory starting from the current offset given by the free memory pointer."
/// according to https://docs.soliditylang.org/en/latest/assembly.html#memory-safety.
/// When bubbling up the revert reason, it is safe to overwrite the free memory pointer 0x40 and the zero pointer 0x60
/// before exiting because a contract obtains a freshly cleared instance of memory for each message call.
library NPMCaller {
    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    /// function throws for queries about the zero address.
    /// @param npm Uniswap v3 Nonfungible Position Manager
    /// @param owner An address for whom to query the balance
    /// @return amount The number of NFTs owned by `owner`, possibly zero
    function balanceOf(INPM npm, address owner) internal view returns (uint256 amount) {
        bytes4 selector = IERC721.balanceOf.selector;
        assembly ("memory-safe") {
            // Write the abi-encoded calldata into memory.
            mstore(0, selector)
            mstore(4, owner)
            // We use 36 because of the length of our calldata.
            // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
            if iszero(staticcall(gas(), npm, 0, 0x24, 0, 0x20)) {
                returndatacopy(0, 0, returndatasize())
                // Bubble up the revert reason.
                revert(0, returndatasize())
            }
            amount := mload(0)
        }
    }

    /// @dev Returns the total amount of tokens stored by the contract.
    function totalSupply(INPM npm) internal view returns (uint256 amount) {
        bytes4 selector = IERC721Enumerable.totalSupply.selector;
        assembly ("memory-safe") {
            // Write the function selector into memory.
            mstore(0, selector)
            // We use 4 because of the length of our calldata.
            // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
            // `totalSupply` should never revert according to the ERC721 standard.
            amount := mload(iszero(staticcall(gas(), npm, 0, 4, 0, 0x20)))
        }
    }

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    /// about them do throw.
    /// @param npm Uniswap v3 Nonfungible Position Manager
    /// @param tokenId The identifier for an NFT
    /// @return owner The address of the owner of the NFT
    function ownerOf(INPM npm, uint256 tokenId) internal view returns (address owner) {
        bytes4 selector = IERC721.ownerOf.selector;
        assembly ("memory-safe") {
            // Write the abi-encoded calldata into memory.
            mstore(0, selector)
            mstore(4, tokenId)
            // We use 36 because of the length of our calldata.
            // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
            if iszero(staticcall(gas(), npm, 0, 0x24, 0, 0x20)) {
                returndatacopy(0, 0, returndatasize())
                // Bubble up the revert reason.
                revert(0, returndatasize())
            }
            owner := mload(0)
        }
    }

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `tokenId` is not a valid NFT.
    /// @param npm Uniswap v3 Nonfungible Position Manager
    /// @param tokenId The NFT to find the approved address for
    /// @return operator The approved address for this NFT, or the zero address if there is none
    function getApproved(INPM npm, uint256 tokenId) internal view returns (address operator) {
        bytes4 selector = IERC721.getApproved.selector;
        assembly ("memory-safe") {
            // Write the abi-encoded calldata into memory.
            mstore(0, selector)
            mstore(4, tokenId)
            // We use 36 because of the length of our calldata.
            // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
            if iszero(staticcall(gas(), npm, 0, 0x24, 0, 0x20)) {
                returndatacopy(0, 0, returndatasize())
                // Bubble up the revert reason.
                revert(0, returndatasize())
            }
            operator := mload(0)
        }
    }

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    /// Throws unless `msg.sender` is the current NFT owner, or an authorized
    /// operator of the current owner.
    /// @param npm Uniswap v3 Nonfungible Position Manager
    /// @param spender The new approved NFT controller
    /// @param tokenId The NFT to approve
    function approve(INPM npm, address spender, uint256 tokenId) internal {
        bytes4 selector = IERC721.approve.selector;
        assembly ("memory-safe") {
            // Write the abi-encoded calldata into memory.
            mstore(0, selector)
            mstore(4, spender)
            mstore(0x24, tokenId)
            // We use 68 because of the length of our calldata.
            if iszero(call(gas(), npm, 0, 0, 0x44, 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                // Bubble up the revert reason.
                revert(0, returndatasize())
            }
            // Clear first 4 bytes of the free memory pointer.
            mstore(0x24, 0)
        }
    }

    /// @notice Query if an address is an authorized operator for another address
    /// @param npm Uniswap v3 Nonfungible Position Manager
    /// @param owner The address that owns the NFTs
    /// @param operator The address that acts on behalf of the owner
    /// @return isApproved True if `operator` is an approved operator for `owner`, false otherwise
    function isApprovedForAll(INPM npm, address owner, address operator) internal view returns (bool isApproved) {
        bytes4 selector = IERC721.isApprovedForAll.selector;
        assembly ("memory-safe") {
            // Write the abi-encoded calldata into memory.
            mstore(0, selector)
            mstore(4, owner)
            mstore(0x24, operator)
            // We use 68 because of the length of our calldata.
            // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
            // `isApprovedForAll` should never revert according to the ERC721 standard.
            isApproved := mload(iszero(staticcall(gas(), npm, 0, 0x44, 0, 0x20)))
            // Clear first 4 bytes of the free memory pointer.
            mstore(0x24, 0)
        }
    }

    /// @notice Enable or disable approval for a third party ("operator") to manage
    /// all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    /// multiple operators per owner.
    /// @param operator Address to add to the set of authorized operators
    /// @param approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(INPM npm, address operator, bool approved) internal {
        bytes4 selector = IERC721.setApprovalForAll.selector;
        assembly ("memory-safe") {
            // Write the abi-encoded calldata into memory.
            mstore(0, selector)
            mstore(4, operator)
            mstore(0x24, approved)
            // We use 68 because of the length of our calldata.
            if iszero(call(gas(), npm, 0, 0, 0x44, 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                // Bubble up the revert reason.
                revert(0, returndatasize())
            }
            // Clear first 4 bytes of the free memory pointer.
            mstore(0x24, 0)
        }
    }

    /// @dev Equivalent to `INonfungiblePositionManager.factory`
    /// @param npm Nonfungible position manager
    function factory(INPM npm) internal view returns (address f) {
        bytes4 selector = IPeripheryImmutableState.factory.selector;
        assembly ("memory-safe") {
            // Write the function selector into memory.
            mstore(0, selector)
            // We use 4 because of the length of our calldata.
            // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
            if iszero(staticcall(gas(), npm, 0, 4, 0, 0x20)) {
                revert(0, 0)
            }
            f := mload(0)
        }
    }

    /// @dev Equivalent to `INonfungiblePositionManager.positions(tokenId)`
    /// @param npm Uniswap v3 Nonfungible Position Manager
    /// @param tokenId The ID of the token that represents the position
    function positionsFull(INPM npm, uint256 tokenId) internal view returns (PositionFull memory pos) {
        bytes4 selector = INPM.positions.selector;
        assembly ("memory-safe") {
            // Write the abi-encoded calldata into memory.
            mstore(0, selector)
            mstore(4, tokenId)
            // We use 36 because of the length of our calldata.
            // We copy up to 384 bytes of return data at pos's pointer.
            if iszero(staticcall(gas(), npm, 0, 0x24, pos, 0x180)) {
                // Bubble up the revert reason.
                revert(pos, returndatasize())
            }
        }
    }

    /// @dev Equivalent to `INonfungiblePositionManager.positions(tokenId)`
    /// @param npm Uniswap v3 Nonfungible Position Manager
    /// @param tokenId The ID of the token that represents the position
    function positions(INPM npm, uint256 tokenId) internal view returns (Position memory pos) {
        bytes4 selector = INPM.positions.selector;
        assembly ("memory-safe") {
            // Write the abi-encoded calldata into memory.
            mstore(0, selector)
            mstore(4, tokenId)
            // We use 36 because of the length of our calldata.
            // We copy up to 256 bytes of return data at `pos` which is the free memory pointer.
            if iszero(staticcall(gas(), npm, 0, 0x24, pos, 0x100)) {
                // Bubble up the revert reason.
                revert(pos, returndatasize())
            }
            // Move the free memory pointer to the end of the struct.
            mstore(0x40, add(pos, 0x100))
            // Skip the first two struct members.
            pos := add(pos, 0x40)
        }
    }

    /// @dev Equivalent to `INonfungiblePositionManager.mint`
    /// @param npm Uniswap v3 Nonfungible Position Manager
    /// @param params The parameters for minting a position
    function mint(
        INPM npm,
        INPM.MintParams memory params
    ) internal returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) {
        uint32 selector = uint32(INPM.mint.selector);
        assembly ("memory-safe") {
            // Cache the free memory pointer.
            let fmp := mload(0x40)
            // Cache the memory word before `params`.
            let memBeforeParams := sub(params, 0x20)
            let wordBeforeParams := mload(memBeforeParams)
            // Write the function selector 4 bytes before `params`.
            mstore(memBeforeParams, selector)
            // We use 356 because of the length of our calldata.
            // We copy up to 128 bytes of return data at the free memory pointer.
            if iszero(call(gas(), npm, 0, sub(params, 4), 0x164, 0, 0x80)) {
                // Bubble up the revert reason.
                revert(0, returndatasize())
            }
            // Read the return data.
            tokenId := mload(0)
            liquidity := mload(0x20)
            amount0 := mload(0x40)
            amount1 := mload(0x60)
            // Restore the free memory pointer, zero pointer and memory word before `params`.
            // `memBeforeParams` >= 0x60 so restore it after `mload`.
            mstore(memBeforeParams, wordBeforeParams)
            mstore(0x40, fmp)
            mstore(0x60, 0)
        }
    }

    /// @dev Equivalent to `INonfungiblePositionManager.increaseLiquidity`
    /// @param npm Uniswap v3 Nonfungible Position Manager
    /// @param params The parameters for increasing liquidity in a position
    function increaseLiquidity(
        INPM npm,
        INPM.IncreaseLiquidityParams memory params
    ) internal returns (uint128 liquidity, uint256 amount0, uint256 amount1) {
        uint32 selector = uint32(INPM.increaseLiquidity.selector);
        assembly ("memory-safe") {
            // Cache the free memory pointer.
            let fmp := mload(0x40)
            // Cache the memory word before `params`.
            let memBeforeParams := sub(params, 0x20)
            let wordBeforeParams := mload(memBeforeParams)
            // Write the function selector 4 bytes before `params`.
            mstore(memBeforeParams, selector)
            // We use 196 because of the length of our calldata.
            // We copy up to 96 bytes of return data at the free memory pointer.
            if iszero(call(gas(), npm, 0, sub(params, 4), 0xc4, 0, 0x60)) {
                returndatacopy(0, 0, returndatasize())
                // Bubble up the revert reason.
                revert(0, returndatasize())
            }
            // Restore the memory word before `params`.
            mstore(memBeforeParams, wordBeforeParams)
            // Read the return data.
            liquidity := mload(0)
            amount0 := mload(0x20)
            amount1 := mload(0x40)
            // Restore the free memory pointer.
            mstore(0x40, fmp)
        }
    }

    /// @dev Equivalent to `INonfungiblePositionManager.decreaseLiquidity`
    /// @param npm Uniswap v3 Nonfungible Position Manager
    /// @param params The parameters for decreasing liquidity in a position
    function decreaseLiquidity(
        INPM npm,
        INPM.DecreaseLiquidityParams memory params
    ) internal returns (uint256 amount0, uint256 amount1) {
        uint32 selector = uint32(INPM.decreaseLiquidity.selector);
        assembly ("memory-safe") {
            // Cache the memory word before `params`.
            let memBeforeParams := sub(params, 0x20)
            let wordBeforeParams := mload(memBeforeParams)
            // Write the function selector 4 bytes before `params`.
            mstore(memBeforeParams, selector)
            // We use 164 because of the length of our calldata.
            // We use 0 and 64 to copy up to 64 bytes of return data into the scratch space.
            if iszero(call(gas(), npm, 0, sub(params, 4), 0xa4, 0, 0x40)) {
                returndatacopy(0, 0, returndatasize())
                // Bubble up the revert reason.
                revert(0, returndatasize())
            }
            // Restore the memory word before `params`.
            mstore(memBeforeParams, wordBeforeParams)
            // Read the return data.
            amount0 := mload(0)
            amount1 := mload(0x20)
        }
    }

    /// @dev Equivalent to `INonfungiblePositionManager.burn`
    /// @param npm Uniswap v3 Nonfungible Position Manager
    /// @param tokenId The token ID of the position to burn
    function burn(INPM npm, uint256 tokenId) internal {
        bytes4 selector = INPM.burn.selector;
        assembly ("memory-safe") {
            // Write the abi-encoded calldata into memory.
            mstore(0, selector)
            mstore(4, tokenId)
            // We use 36 because of the length of our calldata.
            if iszero(call(gas(), npm, 0, 0, 0x24, 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                // Bubble up the revert reason.
                revert(0, returndatasize())
            }
        }
    }

    /// @dev Equivalent to `INonfungiblePositionManager.collect`
    /// @param npm Uniswap v3 Nonfungible Position Manager
    /// @param tokenId The token ID of the position to collect fees for
    /// @param recipient The address that receives the fees
    function collect(INPM npm, uint256 tokenId, address recipient) internal returns (uint256 amount0, uint256 amount1) {
        bytes4 selector = INPM.collect.selector;
        assembly ("memory-safe") {
            // Get a pointer to some free memory.
            let fmp := mload(0x40)
            mstore(fmp, selector)
            mstore(add(fmp, 4), tokenId)
            mstore(add(fmp, 0x24), recipient)
            // amount0Max = amount1Max = type(uint128).max
            mstore(add(fmp, 0x44), 0xffffffffffffffffffffffffffffffff)
            mstore(add(fmp, 0x64), 0xffffffffffffffffffffffffffffffff)
            // We use 132 because of the length of our calldata.
            // We use 0 and 64 to copy up to 64 bytes of return data into the scratch space.
            if iszero(call(gas(), npm, 0, fmp, 0x84, 0, 0x40)) {
                returndatacopy(0, 0, returndatasize())
                // Bubble up the revert reason.
                revert(0, returndatasize())
            }
            amount0 := mload(0)
            amount1 := mload(0x20)
        }
    }

    /// @dev Equivalent to `INonfungiblePositionManager.permit`
    /// @param npm Uniswap v3 Nonfungible Position Manager
    /// @param spender The account that is being approved
    /// @param tokenId The ID of the token that is being approved for spending
    /// @param deadline The deadline timestamp by which the call must be mined for the approve to work
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function permit(
        INPM npm,
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        bytes4 selector = IERC721Permit.permit.selector;
        assembly ("memory-safe") {
            // Get a pointer to some free memory.
            let fmp := mload(0x40)
            mstore(fmp, selector)
            mstore(add(fmp, 4), spender)
            mstore(add(fmp, 0x24), tokenId)
            mstore(add(fmp, 0x44), deadline)
            mstore(add(fmp, 0x64), v)
            mstore(add(fmp, 0x84), r)
            mstore(add(fmp, 0xa4), s)
            // We use 196 because of the length of our calldata.
            if iszero(call(gas(), npm, 0, fmp, 0xc4, 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                // Bubble up the revert reason.
                revert(0, returndatasize())
            }
        }
    }
}
