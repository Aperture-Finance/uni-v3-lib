// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "src/NPMCaller.sol";
import "./Base.t.sol";

/// @dev Expose internal functions to test the NPMCaller library.
contract NPMCallerWrapper {
    using SafeTransferLib for address;

    INonfungiblePositionManager immutable npm;

    constructor(INonfungiblePositionManager _npm) {
        npm = _npm;
    }

    function positionsFull(
        uint256 tokenId
    ) external view returns (PositionFull memory) {
        return NPMCaller.positionsFull(npm, tokenId);
    }

    function positions(
        uint256 tokenId
    ) external view returns (Position memory) {
        return NPMCaller.positions(npm, tokenId);
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        return NPMCaller.ownerOf(npm, tokenId);
    }

    function getApproved(uint256 tokenId) external view returns (address) {
        return NPMCaller.getApproved(npm, tokenId);
    }

    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool) {
        return NPMCaller.isApprovedForAll(npm, owner, operator);
    }

    function mint(
        INPM.MintParams memory params
    ) external returns (uint256, uint128, uint256, uint256) {
        uint256 amount0Desired = params.amount0Desired;
        uint256 amount1Desired = params.amount1Desired;
        if (amount0Desired != 0) {
            address token0 = params.token0;
            token0.safeTransferFrom(msg.sender, address(this), amount0Desired);
            token0.safeApprove(address(npm), amount0Desired);
        }
        if (amount1Desired != 0) {
            address token1 = params.token1;
            token1.safeTransferFrom(msg.sender, address(this), amount1Desired);
            token1.safeApprove(address(npm), amount1Desired);
        }
        return NPMCaller.mint(npm, params);
    }

    function increaseLiquidity(
        INPM.IncreaseLiquidityParams memory params
    ) external returns (uint256, uint256, uint256) {
        Position memory pos = NPMCaller.positions(npm, params.tokenId);
        uint256 amount0Desired = params.amount0Desired;
        uint256 amount1Desired = params.amount1Desired;
        if (amount0Desired != 0) {
            address token0 = pos.token0;
            token0.safeTransferFrom(msg.sender, address(this), amount0Desired);
            token0.safeApprove(address(npm), amount0Desired);
        }
        if (amount1Desired != 0) {
            address token1 = pos.token1;
            token1.safeTransferFrom(msg.sender, address(this), amount1Desired);
            token1.safeApprove(address(npm), amount1Desired);
        }
        return NPMCaller.increaseLiquidity(npm, params);
    }

    function decreaseLiquidity(
        INPM.DecreaseLiquidityParams memory params
    ) external returns (uint256, uint256) {
        return NPMCaller.decreaseLiquidity(npm, params);
    }

    function burn(uint256 tokenId) external {
        return NPMCaller.burn(npm, tokenId);
    }

    function collect(
        uint256 tokenId,
        address recipient
    ) external returns (uint256, uint256) {
        return NPMCaller.collect(npm, tokenId, recipient);
    }

    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        return NPMCaller.permit(npm, spender, tokenId, deadline, v, r, s);
    }
}

/// @dev Test the NPMCaller library.
contract NPMCallerTest is BaseTest {
    using SafeTransferLib for address;

    NPMCallerWrapper internal npmCaller;
    bytes32 internal PERMIT_TYPEHASH;
    bytes32 internal DOMAIN_SEPARATOR;
    address internal user;
    uint256 internal pk;

    function setUp() public override {
        createFork();
        npmCaller = new NPMCallerWrapper(npm);
        PERMIT_TYPEHASH = npm.PERMIT_TYPEHASH();
        DOMAIN_SEPARATOR = npm.DOMAIN_SEPARATOR();
        (user, pk) = makeAddrAndKey("user");
    }

    /// @dev Returns the digest used in the permit signature verification
    function permitDigest(
        address spender,
        uint256 tokenId,
        uint256 deadline
    ) internal view returns (bytes32) {
        (uint96 nonce, , , , , , , , , , , ) = npm.positions(tokenId);
        return
            ECDSA.toTypedDataHash(
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        spender,
                        tokenId,
                        nonce,
                        deadline
                    )
                )
            );
    }

    /// @dev Signs a permit digest with a private key
    function permitSig(
        address spender,
        uint256 tokenId,
        uint256 deadline
    ) internal view returns (uint8 v, bytes32 r, bytes32 s) {
        return vm.sign(pk, permitDigest(spender, tokenId, deadline));
    }

    /// forge-config: default.fuzz.runs = 256
    /// forge-config: ci.fuzz.runs = 256
    function testFuzz_PositionsFull(uint256 tokenId) public {
        tokenId = bound(tokenId, 1, 10000);
        try npmCaller.positionsFull(tokenId) returns (PositionFull memory pos) {
            (
                uint96 nonce,
                ,
                address token0,
                ,
                ,
                int24 tickLower,
                ,
                uint128 liquidity,
                ,
                ,
                ,
                uint128 tokensOwed1
            ) = npm.positions(tokenId);
            assertEq(nonce, pos.nonce, "nonce");
            assertEq(token0, pos.token0, "token0");
            assertEq(tickLower, pos.tickLower, "tickLower");
            assertEq(liquidity, pos.liquidity, "liquidity");
            assertEq(tokensOwed1, pos.tokensOwed1, "tokensOwed1");
        } catch Error(string memory reason) {
            assertEq(reason, "Invalid token ID");
        }
    }

    /// forge-config: default.fuzz.runs = 256
    /// forge-config: ci.fuzz.runs = 256
    function testFuzz_Positions(uint256 tokenId) public {
        tokenId = bound(tokenId, 1, 10000);
        try npmCaller.positions(tokenId) returns (Position memory pos) {
            (
                ,
                ,
                address token0,
                address token1,
                uint24 fee,
                int24 tickLower,
                int24 tickUpper,
                uint128 liquidity,
                ,
                ,
                ,

            ) = npm.positions(tokenId);
            assertEq(token0, pos.token0, "token0");
            assertEq(token1, pos.token1, "token1");
            assertEq(fee, pos.fee, "fee");
            assertEq(tickLower, pos.tickLower, "tickLower");
            assertEq(tickUpper, pos.tickUpper, "tickUpper");
            assertEq(liquidity, pos.liquidity, "liquidity");
        } catch Error(string memory reason) {
            assertEq(reason, "Invalid token ID");
        }
    }

    function testRevert_Positions() public {
        vm.expectRevert("Invalid token ID");
        npmCaller.positions(0);
    }

    /// forge-config: default.fuzz.runs = 256
    /// forge-config: ci.fuzz.runs = 256
    function testFuzz_OwnerOf(uint256 tokenId) public {
        tokenId = bound(tokenId, 1, 10000);
        try npmCaller.ownerOf(tokenId) returns (address owner) {
            assertEq(owner, npm.ownerOf(tokenId), "ownerOf");
        } catch Error(string memory reason) {
            assertEq(reason, "ERC721: owner query for nonexistent token");
        }
    }

    function testRevert_OwnerOf() public {
        vm.expectRevert("ERC721: owner query for nonexistent token");
        npmCaller.ownerOf(0);
    }

    /// forge-config: default.fuzz.runs = 256
    /// forge-config: ci.fuzz.runs = 256
    function testFuzz_GetApproved(uint256 tokenId) public {
        tokenId = bound(tokenId, 1, 10000);
        try npmCaller.getApproved(tokenId) returns (address operator) {
            assertEq(operator, npm.getApproved(tokenId), "getApproved");
        } catch Error(string memory reason) {
            assertEq(reason, "ERC721: approved query for nonexistent token");
        }
    }

    function testRevert_GetApproved() public {
        vm.expectRevert("ERC721: approved query for nonexistent token");
        npmCaller.getApproved(0);
    }

    function test_IsApprovedForAll() public {
        address owner = npm.ownerOf(npm.totalSupply());
        assertEq(
            npmCaller.isApprovedForAll(owner, address(this)),
            npm.isApprovedForAll(owner, address(this)),
            "isApprovedForAll"
        );
    }

    /// forge-config: default.fuzz.runs = 256
    /// forge-config: ci.fuzz.runs = 256
    function testFuzz_IsApprovedForAll(uint256 tokenId) public {
        tokenId = bound(tokenId, 1, 10000);
        try npmCaller.ownerOf(tokenId) returns (address owner) {
            assertEq(
                npmCaller.isApprovedForAll(owner, address(this)),
                false,
                "is approved"
            );
            vm.prank(owner);
            npm.setApprovalForAll(address(this), true);
            assertEq(
                npmCaller.isApprovedForAll(owner, address(this)),
                true,
                "not approved"
            );
        } catch Error(string memory reason) {
            assertEq(reason, "ERC721: owner query for nonexistent token");
        }
    }

    function test_Mint() public returns (uint256 tokenId) {
        int24 tick = matchSpacing(currentTick());
        uint256 amount1Desired = 1e18;
        address _token1 = token1;
        deal(_token1, address(this), amount1Desired);
        NPMCallerWrapper _npmCaller = npmCaller;
        _token1.safeApprove(address(_npmCaller), amount1Desired);
        (tokenId, , , ) = _npmCaller.mint(
            INPM.MintParams({
                token0: token0,
                token1: _token1,
                fee: fee,
                tickLower: tick - tickSpacing,
                tickUpper: tick,
                amount0Desired: 0,
                amount1Desired: amount1Desired,
                amount0Min: 0,
                amount1Min: 0,
                recipient: user,
                deadline: block.timestamp
            })
        );
    }

    function test_Permit() public {
        uint256 tokenId = test_Mint();
        NPMCallerWrapper _npmCaller = npmCaller;
        assertEq(_npmCaller.getApproved(tokenId), address(0), "approved");
        uint256 deadline = block.timestamp;
        (uint8 v, bytes32 r, bytes32 s) = permitSig(
            address(_npmCaller),
            tokenId,
            deadline
        );
        _npmCaller.permit(address(_npmCaller), tokenId, deadline, v, r, s);
        assertEq(
            _npmCaller.getApproved(tokenId),
            address(_npmCaller),
            "not approved"
        );
    }
}
