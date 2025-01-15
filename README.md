# Copy-On-Write (COW) Fork in xv6

This project implements a **Copy-On-Write (COW) fork** mechanism in xv6, a simple Unix-like teaching operating system. The COW implementation optimizes memory usage by sharing physical pages between processes until a write operation requires a private copy of the page.

---

## **Key Features**

1. **Efficient Memory Sharing**
   - Physical memory pages are shared between parent and child processes after a fork, reducing memory overhead.
   
2. **Lazy Copying**
   - New pages are allocated only when a write operation occurs on a shared page, minimizing unnecessary memory allocations.

3. **Reference Counting**
   - Tracks the number of processes referencing each physical page to manage shared resources effectively.

4. **RISC-V PTE Modifications**
   - Uses RSW (Reserved for Software) bits in the RISC-V Page Table Entry (PTE) to mark pages as COW.

---

## **Implementation Details**

### **1. Reference Counter Array**
- A global reference counter array is introduced to track the number of page table entries referring to each physical page.
- Protected by a spinlock to ensure thread-safe operations during fork, page fault handling, and process exit.

### **2. `uvmcopy()`**
- Modified to share the parent’s physical pages with the child instead of duplicating them.
- Sets the `PTE_W` (writable) flag to 0 and marks the COW flag as 1 in the RSW bits.
- Example:
  ```c
  if (pte & PTE_W) {
      pte &= ~PTE_W;  // Remove write permission
      pte |= PTE_COW; // Mark as COW
  }
  ```

### **3. `copyout()`**
- Handles COW page faults when a process attempts to write to a shared page.
- Allocates a new writable page using `kalloc()`, copies the content of the shared page using `memmove()`, and updates the page table entry.
- Adjusts reference counters:
  - Decrements the reference counter for the old page.
  - Frees the old page if no references remain.

### **4. `usertrap()`**
- Modified to handle page faults caused by write attempts to COW-marked pages.
- For a COW page fault:
  - Allocates a new page.
  - Copies the content from the old page to the new page.
  - Updates the page table to point to the new writable page.
  - Restarts the instruction by setting `epc` (Exception Program Counter) to `r_sepc()`.

---

## **Workflow Example**

1. **Forking**
   - Parent and child processes share physical memory pages with the COW flag enabled.
   
2. **Page Fault Handling**
   - A write operation to a shared page triggers a page fault.
   - `usertrap()` identifies the fault as a COW fault and allocates a new page for the writing process.

3. **Reference Counter Management**
   - Reference counters are incremented or decremented as pages are shared or freed.
   - Pages are freed only when the reference counter reaches zero.

---

## **Testing the Implementation**

1. **Test 1: Memory Sharing**
   - Fork a child process and verify that no new memory pages are allocated immediately.

2. **Test 2: Lazy Copying**
   - Perform a write operation in the child process and ensure a new page is allocated for the modified memory region.

3. **Test 3: Reference Counting**
   - Verify the reference counters increase and decrease appropriately during fork, write operations, and process exit.

4. **Test 4: Page Fault Handling**
   - Induce COW page faults and ensure the process continues execution correctly after the fault.

---

## **Challenges and Considerations**

1. **Synchronization**
   - Spinlocks are used to prevent race conditions during reference counter updates.

2. **Efficient Resource Management**
   - Proper handling of edge cases, such as simultaneous page access by multiple processes, to ensure memory consistency.

3. **Compatibility**
   - Ensure the implementation does not break existing functionality in xv6.

---

## **Future Enhancements**

1. **Shared Memory Regions**
   - Extend the COW mechanism to support shared memory segments explicitly.

2. **Optimized Page Fault Handling**
   - Reduce overhead during page fault resolution by exploring techniques like speculative page copying.

3. **Testing Framework**
   - Develop a comprehensive testing suite for stress-testing COW functionality under heavy workloads.

---

## **Acknowledgments**
This project is part of a deep dive into operating system design and implementation, focusing on efficient memory management techniques. Feedback and suggestions are welcome!

