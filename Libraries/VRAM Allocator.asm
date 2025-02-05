; WORK IN PROGRESS

; -----------------------------------------------------------------------------------------------------------------------------------
; INPUT:
;
; RETURNS:
;
; -----------------------------------------------------------------------------------------------------------------------------------
VALLOC_InitLists:
		lea	(vallocNodeList).w,a6			; Load the address of the first node in the list into a6.
		
		move.w	a6,(vallocFreeHead).w			; Set the initial head of the free list to the very first node.
		move.w	#vnode,d0				; Load the size of each node entry to register d0.

	; initialize the free head node
		move.w	a6,vnode.next(a6)			; Move the address of the current node to its 'next' pointer.
		add.w	d0,vnode.next(a6)			; Add offset of the next node to generate the correct address.
		clr.w	vnode.prev(a6)				; Clear the 'previous' pointer on the head node.

		move.w	(vallocStartTile).w,vnode.start(a6)	; Set the starting tile ID to the beginning of the VRAM segment the allocator controls.
		move.w	(vallocEndTile).w,d1			; Load the ending tile ID into register d1.
		move.w	d1,vnode.end(a6)			; Set the ending tile ID to the end of the VRAM segment the allocator controls.

		moveq	#VALLOC_MAX_NODES-1-1,d7		; Set the loop counter.

.initRemainingNodes:
		add.w	d0,a6					; Load the next node.

		move.w	a6,vnode.next(a6)			; Move the address of the current node to its 'next' pointer.
		add.w	d0,vnode.next(a6)			; Add offset of the next node to generate the correct address.

		move.w	a6,vnode.prev(a6)			; Move the address of the current node to its 'previous' pointer.
		sub.w	d0,vnode.prev(a6)			; Subtract offset of the next node to generate the correct address.

		move.w	d1,vnode.start(a6)			; Set the starting and ending tile ID to the end of the VRAM segment, forming an empty node.
		move.w	d1,vnode.end(a6)			; ^
		dbf	d7,.initRemainingNodes			; Loop until all the remaining nodes are initialized.

		move.w	a6,(vallocFreeTail).w			; Make the last node we initialized the tail of the free list.
		clr.w	vnode.next(a6)				; Clear its next pointer.

		clr.w	(vallocLeftover).w			; Initialize the leftover VRAM variable.
		clr.l	(vallocHead).w				; Initialize the allocated list head and tail pointers.
		rts
; -----------------------------------------------------------------------------------------------------------------------------------
; INPUT:
;	d0.w - 0
;	d1.w - number of tiles used by object
;
; RETURNS:
;	a6.w - Pointer to the allocated node assigned to this object
;	ccr - Return flag (n=1: allocation failed, n=0: success)
; -----------------------------------------------------------------------------------------------------------------------------------
VALLOC_AllocateDynamic:
		clr.w	d0					; Ensure that the identifier passed to the main allocation logic is zero.
		bra.s	VALLOC_NewAllocation			; Branch ahead to the main allocation logic.
; -----------------------------------------------------------------------------------------------------------------------------------
; INPUT:
;	d0.w - unique ID to mark the node with
;	d1.w - number of tiles used by object
;
; RETURNS:
;	a6.w - Pointer to the allocated node assigned to this object
;	ccr - Return flag (n=1: allocation failed, z=1: success (found existing allocation), n=0: success (new allocation))
; -----------------------------------------------------------------------------------------------------------------------------------
VALLOC_AllocateStatic:
		tst.w	(vallocHead).w				; Are there any allocated nodes to check?
		beq.s	VALLOC_NewAllocation			; If not, invoke a new allocation.

		movea.w	(vallocHead).w,a6			; Otherwise, load the first allocated node so we can begin redundancy checks.

.checkIdentifier:
		cmp.w	vnode.id(a6),d0				; Does the identifier attached to this node match the one sent by the caller? 
		beq.s	.alreadyAllocated			; If so, space is already allocated for this instance type; branch. 
		
		tst.w	vnode.next(a6)				; Otherwise, check if there are any more allocated nodes in the list.
		beq.s	VALLOC_NewAllocation			; If this was the last node, branch and attempt to invoke a new allocation.
		
		movea.w	vnode.next(a6),a6			; If not, load the next allocated node.
		bra.s	.checkIdentifier			; Loop back and continue performing the search.
; -----------------------------------------------------------------------------------------------------------------------------------
.alreadyAllocated:
		addq.w	#1,vnode.count(a6)			; Increment the instance counter.
		ori	#4,ccr					; Set the zero flag on the ccr, indicating an existing allocation was found.
		rts						; Return.
; -----------------------------------------------------------------------------------------------------------------------------------
; INPUT:
;	d0.w - unique ID to mark the node with
;	d1.w - number of tiles used by object
;
; RETURNS:
;	d0.w - VRAM tile ID assigned to the caller
;	ccr - Return flag (n=1: allocation failed, n=0: success)
; -----------------------------------------------------------------------------------------------------------------------------------
VALLOC_NewAllocation:
	;	movem.l	d2/a5,-(sp)				; Save registers d2 and a5.
		move.w	(vallocFreeHead).w,d2			; Are there any free nodes?
		beq.s	.allocationFailed			; If not, exit with an allocation failure.

.lookForBlock:
		movea.w	d2,a6					; Load the free node.
		move.w	vnode.end(a6),d2			; Get the size of this memory block (in tiles).
		sub.w	vnode.start(a6),d2			; ^

		cmp.w	d1,d2					; Is this block large enough?
		bge.s	.foundBlock				; If so, break out of the loop and allocate this space.

		move.w	vnode.next(a6),d2			; Are there any free nodes left?
		beq.s	.allocationFailed			; If not, exit with an allocation failure.
		bra.s	.lookForBlock				; Otherwise, loop and continue searching for a large enough block.
; -----------------------------------------------------------------------------------------------------------------------------------
.allocationFailed:
	;	movem.l	(sp)+,d2/a5				; Restore registers d2 and a5.
		ori	#8,ccr					; Set the negative flag on the ccr, indicating failure.
		rts						; Return.
; -----------------------------------------------------------------------------------------------------------------------------------
.foundBlock:
		move.w	d0,vnode.id(a6)				; Mark this node with the specified unique identifier.
		move.w	#1,vnode.count(a6)			; Initialize the insance count on this node to 1.
		add.w	vnode.start(a6),d1			; Calculate the ending tile ID for the for this node and save it.
		move.w	d1,vnode.end(a6)			; ^

		move.w	vnode.next(a6),(vallocFreeHead).w	; Make the next node the beginning of the free list.
		bne.s	.notLastFreeNode			; Branch if there is a free node after this.

	; If this node was the last one in the free list, we need to save the starting tile ID of what would have been
	; the next free node so we don't lose access to all of the VRAM tiles after the space this node allocates.
	; This starting tile ID will be re-added to the free list when two adjacent nodes are coalesced.
		clr.w	(vallocFreeTail).w			; Clear the free tail addresses
		move.w	d1,(vallocLeftover).w			; Back up the tile ID indicating leftover VRAM
		bra.s	.insertNewTail

.notLastFreeNode:
		movea.w	vnode.next(a6),a5			; Load the next free node into a5.
		move.w	d1,vnode.start(a5)			; Make this node's ending tile id the start of the next free one.
		clr.w	vnode.prev(a5)				; Nullify the 'previous' pointer on the free head.
		clr.w	vnode.next(a6)				; Nullify the 'next' pointer on the new tail.


.insertNewTail:
		move.w	(vallocTail).w,d2			; Tempoarily load the current tail to register d2.
		beq.s	.initAllocatedList			; If the current allocated list tail is zero, that means we need to initialize the list.

		movea.w	d2,a5					; If the allocation list isn't empty, proceed to append the new tail as normal.
		move.w	a6,(vallocTail).w			; Save the newly allocated node as the new tail.
		move.w	a6,vnode.next(a5)			; Make the 'next' pointer on the old tail point to the new tail.
		move.w	a5,vnode.prev(a6)			; Make the 'previous' pointer on the new tail point back to the old tail.
		clr.w	vnode.next(a6)				; Clear the new tail node's 'next' pointer.

	;	movem.l	(sp)+,d2/a5				; Restore registers d2 and a5.
		andi	#~$C,ccr				; Clear both the zero and negative flags on the ccr, indicating success.
		rts						; Return.
; -----------------------------------------------------------------------------------------------------------------------------------
.initAllocatedList:
		move.w	a6,(vallocHead).w			; Save the newly allocated node as the initial head and tail of the allocated list.
		move.w	a6,(vallocTail).w			; ^
		clr.l	vnode.next(a6)				; Clear the 'next' and 'previous' pointers on this node.

	;	movem.l	(sp)+,d2/a5				; Restore registers d2 and a5.
		andi	#~$C,ccr				; Clear both the zero and negative flags on the ccr, indicating success.
		rts						; Return.
; -----------------------------------------------------------------------------------------------------------------------------------
; INPUT:
;	a6.w - Pointer to the allocated node assigned to this object
;
; RETURNS:
;	ccr - Return flag (n=1: allocation failed, z=1: success (instance count decreased), n=0: success (memory deallocated))
; -----------------------------------------------------------------------------------------------------------------------------------
VALLOC_Deallocate:
	; NOTE: This is not a rigorous test to ensure that a node is valid prior to deallocation; ideally we'd scan the list to find it, but that's slow.
	; Prehaps that's something that can exist in debug builds? Food for thought.
		tst.w	(vallocHead).w				; Are there any nodes to deallocate?
		bne.s	.decrementCount				; If so, assume this is a valid pointer and proceed with the deallocation process.

		ori	#8,ccr					; Set the negative flag on the ccr, indicating failure.
		rts

.decrementCount:
		subq.w	#1,vnode.count(a6)			; Decrement the instance count to see if we need to invoke a deallocation
		beq.s	.checkIfHead				; If the counter hits zero, branch and perform the full deallocation logic
		
		ori	#4,ccr					; Otherwise, set the zero flag on the ccr, indicating there are still objects using this VRAM.
		rts						; Return.
; -----------------------------------------------------------------------------------------------------------------------------------
.checkIfHead:
		move.w	(vallocHead).w,d0			; Load the address of the allocated list head into d0.
		cmp.w	a6,d0					; Is the node we want to deallocate the head of the allocated list?
		bne.s 	.checkIfTail				; If not, check if this node is the tail instead.

		move.w	vnode.next(a6),d0			; Otherwise, load the head's 'next' pointer into d0 so we can make that the new allocated list head.
		beq.s	.bothHeadAndTail			; Branch if it turns out that this node is both the allocated list head AND tail.

		movea.w	d0,a5					; Load the new head of the allocated list into register a5.
		move.w	a5,(vallocHead).w			; Update the allocated list head pointer.
		clr.w	vnode.prev(a5)				; Clear the new list head node's 'previous' pointer.
		bra.s	.invokeDeallocation			; Proceed with deallocation.
; -----------------------------------------------------------------------------------------------------------------------------------
.checkIfTail:
		move.w	(vallocTail).w,d0			; Load the address of the allocated list tail into d0.
		cmp.w	a6,d0					; Is the node we want to deallocate the tail of the allocated list?
		bne.s 	.invokeDeallocation			; If not, proceed with deallocation.

		move.w	vnode.prev(a6),a5			; Otherwise, load the new tail of the allocated list into register a5.
		move.w	a5,(vallocTail).w			; Update the allocated list tail pointer.
		clr.w	vnode.next(a5)				; Clear the new list tail node's 'next' pointer.
		bra.s	.invokeDeallocation			; Proceed with deallocation.
; -----------------------------------------------------------------------------------------------------------------------------------
.bothHeadAndTail:
		clr.l	(vallocHead).w				; Clear the allocated list head and tail pointers entirely.

.invokeDeallocation:
		move.w	(vallocFreeHead).w,d0			; Load the address of the free list head into register d0.
		bne.s	.insertIntoFreeList			; If we loaded a valid (not null) pointer, branch to the insertion logic.

.initFreeList:
		move.w	a6,(vallocFreeHead).w			; Otherwise, use this node as the initial node of the free list.
		move.w	a6,(vallocFreeTail).w			; ^
		bsr.w	.cutFromAllocList
		clr.l	vnode.next(a6)				; Clear the 'next' and 'previous' pointers on this node.

		andi	#~$C,ccr				; Clear both the zero and negative flags on the ccr, indicating successful deallocation.
		rts						; Return.
; -----------------------------------------------------------------------------------------------------------------------------------
.insertIntoFreeList:
		movea.w	d0,a5					; Load the head of the free list into register a5.
		move.w	vnode.start(a5),d0			; Load the starting tile ID of the free list head into register d0.
		cmp.w	vnode.start(a6),d0			; Is the starting tile ID of the free list head greater than the node we're attempting to insert?
		bhi.s	.appendAsHead				; If so, branch to the logic to insert the new node at the beginning of the list.

.findInsertionPoint:
		move.w	vnode.next(a5),d0			; Load the address of the next free node into register d0.
		beq.s	.appendAsTail				; If there is no next node, branch to the logic to insert the new node at the end of the list.

		movea.w	d0,a5					; Load the head of the free list into register a5.
		move.w	vnode.start(a5),d0			; Otherwise, load the starting tile ID of this free node into register d0.
		cmp.w	vnode.start(a6),d0			; Is the starting tile ID of this node greater than the node we're attempting to insert?
		bhi.s	.insertAtIndex				; If so, branch to the logic to insert this node at this index within the free list.
		bra.s	.findInsertionPoint			; Otherwise, loop until we find the appropriate place to insert this within the list.
; -----------------------------------------------------------------------------------------------------------------------------------
; Internal subroutine to cut a node out of the allocation list
; -----------------------------------------------------------------------------------------------------------------------------------
.cutFromAllocList:
		move.w	vnode.next(a6),d0			; load the 'next' pointer into d0.
		beq.s	.cutNodeIsTail

		movea.w	d0,a4					; Load the next node into register a4.
		move.w	vnode.prev(a6),vnode.prev(a4)		; Make its 'previous' pointer skip over the current node.

.cutNodeIsTail:
		move.w	vnode.prev(a6),d0			; load the 'previous' pointer into d0.
		beq.s	.cutNodeIsHead

		movea.w	d0,a4					; Load the previous node into register a4.
		move.w	vnode.next(a6),vnode.next(a4)		; Make its 'next' pointer skip over the current node.

.cutNodeIsHead:
		rts
; -----------------------------------------------------------------------------------------------------------------------------------
.appendAsHead:
		bsr.s	.cutFromAllocList
		move.w	a6,(vallocFreeHead).w			; Set this node as the new head of the free list.
		move.w	a6,vnode.prev(a5)			; Make the old head node point to the new head from its 'previous' pointer.
		move.w	a5,vnode.next(a6)			; Make the new head node point to the old head from its 'next' pointer.
		clr.w	vnode.prev(a6)				; Clear the new head node's 'previous' pointer.
		bra.s	.coalesceNodes				; Branch ahead to the logic that handles coalescing adjacent nodes.
; -----------------------------------------------------------------------------------------------------------------------------------
.appendAsTail:
		bsr.s	.cutFromAllocList
		move.w	a6,(vallocFreeTail).w			; Append this node as the new tail of the free list.
		move.w	a6,vnode.next(a5)			; Make the 'next' pointer on the old tail point to the new tail.
		move.w	a5,vnode.prev(a6)			; Make the 'previous' pointer on the new tail point back to the old tail.
		clr.w	vnode.next(a6)				; Clear the new tail node's 'next' pointer.
		bra.s	.coalesceNodes				; Branch ahead to the logic that handles coalescing adjacent nodes.
; -----------------------------------------------------------------------------------------------------------------------------------
.insertAtIndex:
		bsr.s	.cutFromAllocList
		move.w	vnode.prev(a5),vnode.prev(a6)		; Save the address of the node that comes before the point of insertion so we don't lose it.
		move.w	a6,vnode.prev(a5)			; Make the 'previous' pointer on the node following the point of insertion point to our new node.
		move.w	a5,vnode.next(a6)			; Make the 'next' pointer on the new node point the the node that follows it in the list.

		move.w	vnode.prev(a6),a5			; Load the node preceding the point of insertion into register a5.
		move.w	a6,vnode.next(a5)			; Make the 'next' pointer on the previous node point to the node we just inserted into the list.		

.coalesceNodes:
		move.w	vnode.prev(a6),d0			; Load the address of the prior node into register d0.
		beq.s	.checkNextNode				; If there's no prior node, do not attempt to coalesce more than once; branch ahead.
		bsr.s	.checkNextNode				; Otherwise, use a subroutine call to run the coalesence logic once.
		movea.w	vnode.prev(a6),a6			; Once finished with the first run, move the back to the previous node and fall through to the 2nd run of coalesence.

.checkNextNode:
		move.w	vnode.next(a6),d0			; Load the address of the following node into register d0.
		beq.s	.return					; If there's no following node, do not attempt to coalesce; branch to the return logic.
		
		movea.w	d0,a5					; Load the following node into register a5.
		move.w	vnode.start(a5),d0			; Load the starting tile ID of the following node into d0. 
		cmp.w	vnode.end(a6),d0			; Does the following node's VRAM begin where the current node's VRAM ends?
		bne.s	.return					; If not, we cannot coalesce these nodes; branch to the return logic.

		move.w	vnode.next(a5),d0			; If so, tempoarily load the next node ahead in the list into d0.
		beq.s	.followingNodeIsTail			; Branch if the following node is the tail of the list.

		movea.w	d0,a4					; Load the next node ahead into register a4.
		move.w	a6,vnode.prev(a4)			; Make the next node ahead point back to the node we plan to merge into, cutting the prior node (a5) out of the list.
		move.w	a4,vnode.next(a6)			; Make the 'next' pointer of the current node (a6) point passed the node we're cutting out (a5).

.followingNodeIsTail:
		move.w	vnode.end(a5),vnode.end(a6)		; Overwrite the ending tile ID on the current node (a6) with the ending tile ID of the node we cut out (a5).

		move.w	(vallocEndTile).w,vnode.start(a5)	; Make the node we cut out an empty node that we can append to the list as a tail.
		move.w	(vallocEndTile).w,vnode.end(a5)		; ^

		move.w	(vallocFreeTail).w,d0			; Temporarily load the free list tail into register d0.
		cmp.w	a5,d0					; Is the empty node alread the tail?
		beq.s	.nodeIsAlreadyTail			; If so, branch.

		movea.w	d0,a4					; Load the old tail node into register a4.
		move.w	a5,(vallocFreeTail).w			; Save the node we cut out as the new tail.
		move.w	a5,vnode.next(a4)			; Make the 'next' pointer on the old tail point to the new tail.
		move.w	a4,vnode.prev(a5)			; Make the 'previous' pointer on the new tail point back to the old tail.
		clr.w	vnode.next(a5)				; Clear the new tail node's 'next' pointer.

.nodeIsAlreadyTail:
		move.w	(vallocLeftover).w,d0			; Is there any VRAM that we need to restore access to?
		beq.s	.return					; If not, branch and return.

		clr.w	(vallocLeftover).w			; Clear the leftover VRAM variable.
		move.w	d0,vnode.start(a5)			; Restore acess to any VRAM that was left over after the list was filled.
		move.w	(vallocEndTile).w,vnode.end(a5)		; Set the new tail's ending tile ID to the maximum allowed value.

		move.w	vnode.start(a5),d0			; Load the starting tile ID of the restored VRAM node into d0. 
		cmp.w	vnode.end(a6),d0			; Can we coalesce these nodes?
		bne.s	.return					; If not, branch and return.

		move.w	vnode.end(a5),vnode.end(a6)		; Otherwise, coalesce the restored VRAM into the current node (a6).
		move.w	(vallocEndTile).w,vnode.start(a5)	; Set the starting tile ID to the end of the VRAM segment, forming an empty node at the end of the list (a5).

.return:
		andi	#~$C,ccr				; Clear both the zero and negative flags on the ccr, indicating successful deallocation.
		rts						; Return.
; -----------------------------------------------------------------------------------------------------------------------------------