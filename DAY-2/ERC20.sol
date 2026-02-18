// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IERC20 {
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);

	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address to, uint256 value) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 value) external returns (bool);
	function transferFrom(address from, address to, uint256 value) external returns (bool);
}

interface IERC20Metadata is IERC20 {
	function name() external view returns (string memory);
	function symbol() external view returns (string memory);
	function decimals() external view returns (uint8);
}

contract ERC20 is IERC20Metadata {
	string private _name;
	string private _symbol;
	uint8 private immutable _decimals;

	uint256 private _totalSupply;
	mapping(address account => uint256) private _balances;
	mapping(address owner => mapping(address spender => uint256)) private _allowances;

	error ERC20InvalidSender(address sender);
	error ERC20InvalidReceiver(address receiver);
	error ERC20InvalidApprover(address approver);
	error ERC20InvalidSpender(address spender);
	error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);
	error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

	constructor(
		string memory tokenName,
		string memory tokenSymbol,
		uint8 tokenDecimals,
		uint256 initialSupply,
		address initialOwner
	) {
		if (initialOwner == address(0)) {
			revert ERC20InvalidReceiver(address(0));
		}

		_name = tokenName;
		_symbol = tokenSymbol;
		_decimals = tokenDecimals;

		if (initialSupply > 0) {
			_mint(initialOwner, initialSupply);
		}
	}

	function name() external view override returns (string memory) {
		return _name;
	}

	function symbol() external view override returns (string memory) {
		return _symbol;
	}

	function decimals() external view override returns (uint8) {
		return _decimals;
	}

	function totalSupply() external view override returns (uint256) {
		return _totalSupply;
	}

	function balanceOf(address account) external view override returns (uint256) {
		return _balances[account];
	}

	function allowance(address owner, address spender) external view override returns (uint256) {
		return _allowances[owner][spender];
	}

	function transfer(address to, uint256 value) external override returns (bool) {
		_transfer(msg.sender, to, value);
		return true;
	}

	function approve(address spender, uint256 value) external override returns (bool) {
		_approve(msg.sender, spender, value);
		return true;
	}

	function transferFrom(address from, address to, uint256 value) external override returns (bool) {
		_spendAllowance(from, msg.sender, value);
		_transfer(from, to, value);
		return true;
	}

	function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
		uint256 currentAllowance = _allowances[msg.sender][spender];
		_approve(msg.sender, spender, currentAllowance + addedValue);
		return true;
	}

	function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
		uint256 currentAllowance = _allowances[msg.sender][spender];
		if (currentAllowance < subtractedValue) {
			revert ERC20InsufficientAllowance(spender, currentAllowance, subtractedValue);
		}

		unchecked {
			_approve(msg.sender, spender, currentAllowance - subtractedValue);
		}

		return true;
	}

	function _transfer(address from, address to, uint256 value) internal {
		if (from == address(0)) {
			revert ERC20InvalidSender(address(0));
		}
		if (to == address(0)) {
			revert ERC20InvalidReceiver(address(0));
		}

		_update(from, to, value);
	}

	function _mint(address account, uint256 value) internal {
		if (account == address(0)) {
			revert ERC20InvalidReceiver(address(0));
		}

		_update(address(0), account, value);
	}

	function _burn(address account, uint256 value) internal {
		if (account == address(0)) {
			revert ERC20InvalidSender(address(0));
		}

		_update(account, address(0), value);
	}

	function _approve(address owner, address spender, uint256 value) internal {
		if (owner == address(0)) {
			revert ERC20InvalidApprover(address(0));
		}
		if (spender == address(0)) {
			revert ERC20InvalidSpender(address(0));
		}

		_allowances[owner][spender] = value;
		emit Approval(owner, spender, value);
	}

	function _spendAllowance(address owner, address spender, uint256 value) internal {
		uint256 currentAllowance = _allowances[owner][spender];

		if (currentAllowance != type(uint256).max) {
			if (currentAllowance < value) {
				revert ERC20InsufficientAllowance(spender, currentAllowance, value);
			}

			unchecked {
				_approve(owner, spender, currentAllowance - value);
			}
		}
	}

	function _update(address from, address to, uint256 value) internal {
		if (from == address(0)) {
			_totalSupply += value;
		} else {
			uint256 fromBalance = _balances[from];
			if (fromBalance < value) {
				revert ERC20InsufficientBalance(from, fromBalance, value);
			}

			unchecked {
				_balances[from] = fromBalance - value;
			}
		}

		if (to == address(0)) {
			unchecked {
				_totalSupply -= value;
			}
		} else {
			unchecked {
				_balances[to] += value;
			}
		}

		emit Transfer(from, to, value);
	}
}

