// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// Minimal ERC20 interface for sending and receiving token payments.
interface IERC20 {
	function transfer(address to, uint256 value) external returns (bool);
	function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract SchoolManagment {
	// EMCDS token contract used for all school fee and salary payments.
	IERC20 public constant EMCDS = IERC20(0xDf377902d015e7dA5d60190073cA20B370b97BFE);

	// Deployer becomes the owner and controls admin-only actions.
	address public immutable owner;

	// Student record saved after registration/payment.
	struct Student {
		uint256 id;
		address account;
		string fullName;
		uint16 level;
		uint256 schoolFee;
		bool paymentStatus;
		uint256 paymentTimestamp;
	}

	// Staff record saved after registration and updated on payment.
	struct Staff {
		uint256 id;
		address account;
		string fullName;
		string role;
		bool isPaid;
		uint256 totalPaid;
		uint256 paymentTimestamp;
	}

	// Auto-increment IDs for students and staff.
	uint256 public nextStudentId;
	uint256 public nextStaffId;

	// Maps each level (100/200/300/400) to its school fee amount.
	mapping(uint16 level => uint256 fee) public levelToSchoolFee;
	// Quick lookup: wallet address => student details.
	mapping(address student => Student) private students;
	// Quick lookup: wallet address => staff details.
	mapping(address staff => Staff) private staffs;

	// Arrays used for returning full student/staff lists.
	address[] private studentAccounts;
	address[] private staffAccounts;

	// Emitted when a student is registered and fee payment succeeds.
	event StudentRegistered(
		uint256 indexed studentId,
		address indexed student,
		string fullName,
		uint16 level,
		uint256 feeAmount,
		uint256 paidAt
	);

	// Emitted when a staff member is registered.
	event StaffRegistered(
		uint256 indexed staffId,
		address indexed staff,
		string fullName,
		string role
	);

	// Emitted whenever a staff salary payment is made.
	event StaffPaid(address indexed staff, uint256 amount, uint256 paidAt);
	// Emitted when admin updates fee for a level.
	event SchoolFeeUpdated(uint16 indexed level, uint256 amount);

	// Restricts access to contract owner.
	modifier onlyOwner() {
		require(msg.sender == owner, "Only owner can call");
		_;
	}

	// Constructor sets owner and initial school fees per level.
	constructor(
		uint256 fee100Level,
		uint256 fee200Level,
		uint256 fee300Level,
		uint256 fee400Level
	) {
		owner = msg.sender;

		levelToSchoolFee[100] = fee100Level;
		levelToSchoolFee[200] = fee200Level;
		levelToSchoolFee[300] = fee300Level;
		levelToSchoolFee[400] = fee400Level;
	}

	// Anyone can register a student, but must pay that student's fee in EMCDS.
	function registerStudent(address student, string calldata fullName, uint16 level) external {
		// Basic validations.
		require(student != address(0), "Invalid student address");
		require(bytes(fullName).length > 0, "Name is required");
		require(students[student].account == address(0), "Student already registered");
		require(level == 100 || level == 200 || level == 300 || level == 400, "Invalid level");

		// Read fee configured for the selected level.
		uint256 feeAmount = levelToSchoolFee[level];
		require(feeAmount > 0, "Fee not set for level");

		// Transfer fee from caller to this contract (caller must approve first).
		bool success = EMCDS.transferFrom(msg.sender, address(this), feeAmount);
		require(success, "School fee payment failed");

		// Save student record with payment details.
		nextStudentId += 1;
		students[student] = Student({
			id: nextStudentId,
			account: student,
			fullName: fullName,
			level: level,
			schoolFee: feeAmount,
			paymentStatus: true,
			paymentTimestamp: block.timestamp
		});

		// Keep address for list retrieval.
		studentAccounts.push(student);

		// Log registration for frontend/indexers.
		emit StudentRegistered(nextStudentId, student, fullName, level, feeAmount, block.timestamp);
	}

	// Owner registers staff so they can be paid later.
	function registerStaff(address staff, string calldata fullName, string calldata role) external onlyOwner {
		// Basic validations.
		require(staff != address(0), "Invalid staff address");
		require(bytes(fullName).length > 0, "Name is required");
		require(bytes(role).length > 0, "Role is required");
		require(staffs[staff].account == address(0), "Staff already registered");

		// Create and store staff record.
		nextStaffId += 1;
		staffs[staff] = Staff({
			id: nextStaffId,
			account: staff,
			fullName: fullName,
			role: role,
			isPaid: false,
			totalPaid: 0,
			paymentTimestamp: 0
		});

		// Keep address for list retrieval.
		staffAccounts.push(staff);

		// Log staff registration.
		emit StaffRegistered(nextStaffId, staff, fullName, role);
	}

	// Owner pays staff from contract token balance.
	function payStaff(address staff, uint256 amount) external onlyOwner {
		// Basic validations.
		require(staff != address(0), "Invalid staff address");
		require(amount > 0, "Amount must be greater than zero");
		require(staffs[staff].account != address(0), "Staff not registered");

		// Send EMCDS to staff wallet.
		bool success = EMCDS.transfer(staff, amount);
		require(success, "Staff payment failed");

		// Update last payment info and running total.
		staffs[staff].isPaid = true;
		staffs[staff].totalPaid += amount;
		staffs[staff].paymentTimestamp = block.timestamp;

		// Log salary payment.
		emit StaffPaid(staff, amount, block.timestamp);
	}

	// Owner can change fee amount for any valid level.
	function updateSchoolFee(uint16 level, uint256 amount) external onlyOwner {
		require(level == 100 || level == 200 || level == 300 || level == 400, "Invalid level");
		require(amount > 0, "Fee must be greater than zero");

		// Update state + emit event.
		levelToSchoolFee[level] = amount;
		emit SchoolFeeUpdated(level, amount);
	}

	// Returns details of one student by address.
	function getStudent(address student) external view returns (Student memory) {
		require(students[student].account != address(0), "Student not registered");
		return students[student];
	}

	// Returns all registered students.
	function getAllStudents() external view returns (Student[] memory) {
		uint256 totalStudents = studentAccounts.length;
		Student[] memory allStudents = new Student[](totalStudents);

		// Build the response array from stored addresses.
		for (uint256 i; i < totalStudents; i++) {
			allStudents[i] = students[studentAccounts[i]];
		}

		return allStudents;
	}

	// Returns details of one staff by address.
	function getStaff(address staff) external view returns (Staff memory) {
		require(staffs[staff].account != address(0), "Staff not registered");
		return staffs[staff];
	}

	// Returns all registered staff members.
	function getAllStaffs() external view returns (Staff[] memory) {
		uint256 totalStaffs = staffAccounts.length;
		Staff[] memory allStaffs = new Staff[](totalStaffs);

		// Build the response array from stored addresses.
		for (uint256 i; i < totalStaffs; i++) {
			allStaffs[i] = staffs[staffAccounts[i]];
		}

		return allStaffs;
	}

	// Reads this contract's EMCDS token balance.
	function getContractEMCDSBalance() external view returns (uint256) {
		// Small safety check in case token address has no code in this network.
		return address(EMCDS).code.length > 0 ? _safeTokenBalance() : 0;
	}

	// Internal low-level balance read (works even though balanceOf is not in IERC20 above).
	function _safeTokenBalance() internal view returns (uint256 balance) {
		(bool success, bytes memory data) = address(EMCDS).staticcall(
			abi.encodeWithSignature("balanceOf(address)", address(this))
		);
		require(success && data.length >= 32, "Could not fetch balance");
		balance = abi.decode(data, (uint256));
	}
}
