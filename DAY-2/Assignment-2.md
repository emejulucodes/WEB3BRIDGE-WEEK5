# Solidity Data Locations: Storage, Memory, and Calldata

## 1) Where are structs, mappings, and arrays stored?

In Solidity, these reference types can live in different data locations depending on how they are declared:

- **State variables** (declared at contract level) are stored in **storage** (permanent blockchain state).
- **Local variables** inside functions can be in **memory** (temporary for the function call) or **storage** (reference to existing state).
- **Calldata** is used for external function inputs and is read-only.

### Structs
- As state variables: in **storage**.
- In functions: can be `memory` or `storage` references.

### Arrays
- Dynamic and fixed-size arrays as state variables: in **storage**.
- Function-local arrays can be in **memory**.

### Mappings
- Mappings are only valid in **storage** (state or storage reference).
- They are not iterable and do not store keys directly like arrays.

---

## 2) How do they behave when executed or called?

### Storage
- Persistent between transactions.
- Writing to storage costs more gas.
- Changes remain on-chain after function execution.

### Memory
- Temporary during function execution.
- Cheaper than storage for temporary work.
- Cleared after the function call ends.

### Calldata
- Read-only input data for external calls.
- Very gas-efficient for function parameters.
- Cannot be modified.

### Behavior of reference types
- `storage` variables act as references to on-chain data.
- `memory` variables are copies (unless explicitly assigned as references in specific contexts).
- Updating a `storage` reference updates the original state.

---

## 3) Why don’t you need to specify memory or storage with mappings?

You generally do not specify `memory` for mappings because:

- **Mappings cannot exist in memory** in the way arrays/structs can.
- A mapping is a hash table-like key-to-value lookup over storage slots.
- It has no length and no complete in-memory representation to allocate/copy.

So in practice:
- Contract-level mapping declarations are automatically in **storage**.
- Function parameters/returns cannot be plain mappings in memory for public/external use.
- When you use a mapping from state, Solidity already treats it as storage-based.

---

## Quick Summary

- **Structs/Arrays:** can be storage or memory depending on usage.
- **Mappings:** storage-only.
- **Storage persists**, **memory is temporary**, **calldata is read-only input**.
