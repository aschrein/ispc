;;  Copyright (c) 2020, Intel Corporation
;;  All rights reserved.
;;
;;  Redistribution and use in source and binary forms, with or without
;;  modification, are permitted provided that the following conditions are
;;  met:
;;
;;    * Redistributions of source code must retain the above copyright
;;      notice, this list of conditions and the following disclaimer.
;;
;;    * Redistributions in binary form must reproduce the above copyright
;;      notice, this list of conditions and the following disclaimer in the
;;      documentation and/or other materials provided with the distribution.
;;
;;    * Neither the name of Intel Corporation nor the names of its
;;      contributors may be used to endorse or promote products derived from
;;      this software without specific prior written permission.
;;
;;
;;   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
;;   IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
;;   TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
;;   PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
;;   OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
;;   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
;;   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
;;   PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
;;   LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
;;   NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
;;   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

;; Define i1x4 mask

define(`WIDTH',`4')
;; FIXME: Workaround for "BUILD_OS should be defined to either UNIX or WINDOWS" error
define(`BUILD_OS',`UNIX')
define(`RUNTIME',`32')
define(`MASK',`i32')
define(`HAS_CUSTOM_PER_LANE',`1')

define(`custom_per_lane',`
  br label %pl_entry

pl_entry:
  %pl_mask = bitcast $2 to i128
  %pl_mask_known = call i1 @__is_compile_time_constant_mask($2)
  br i1 %pl_mask_known, label %pl_known_mask, label %pl_unknown_mask

pl_known_mask:
  %pl_is_allon = icmp eq i128 %pl_mask, -1
  br i1 %pl_is_allon, label %pl_all_on, label %pl_unknown_mask

pl_all_on:
  forloop(i, 0, eval($1-1), 
          `patsubst(`$3', `LANE', i)')
  br label %pl_done

pl_unknown_mask:
  br label %pl_loop

pl_loop:
  ;; Loop over each lane and see if we want to do the work for this lane
  %pl_lane = phi i32 [ 0, %pl_unknown_mask ], [ %pl_nextlane, %pl_loopend ]
  %pl_lanemask = phi i128 [ 1, %pl_unknown_mask ], [ %pl_nextlanemask, %pl_loopend ]

  ; is the current lane on?  if so, goto do work, otherwise to end of loop
  %pl_and = and i128 %pl_mask, %pl_lanemask
  %pl_doit = icmp eq i128 %pl_and, %pl_lanemask
  br i1 %pl_doit, label %pl_dolane, label %pl_loopend 

pl_dolane:
  ;; If so, substitute in the code from the caller and replace the LANE
  ;; stuff with the current lane number
  patsubst(`patsubst(`$3', `LANE_ID', `_id')', `LANE', `%pl_lane')
  br label %pl_loopend

pl_loopend:
  %pl_nextlane = add i32 %pl_lane, 1
  %pl_nextlanemask = shl i128 %pl_lanemask, 32

  ; are we done yet?
  %pl_test = icmp ne i32 %pl_nextlane, $1
  br i1 %pl_test, label %pl_loop, label %pl_done

pl_done:
')

include(`util.m4')

stdlib_core()
scans()
reduce_equal(WIDTH)
rdrand_decls()
define_shuffles()
aossoa()
ctlztz()

define void @__masked_store_blend_i8(<WIDTH x i8>* nocapture %ptr, <WIDTH x i8> %new,
                                     <WIDTH x MASK> %mask) nounwind alwaysinline {
  %old = load PTR_OP_ARGS(`<WIDTH x i8> ')  %ptr
  %mask1 = trunc <WIDTH x MASK> %mask to <WIDTH x i1>
  %result = select <WIDTH x i1> %mask1, <WIDTH x i8> %new, <WIDTH x i8> %old
  store <WIDTH x i8> %result, <WIDTH x i8> * %ptr
  ret void
}

define void @__masked_store_blend_i16(<WIDTH x i16>* nocapture %ptr, <WIDTH x i16> %new, 
                                      <WIDTH x MASK> %mask) nounwind alwaysinline {
  %old = load PTR_OP_ARGS(`<WIDTH x i16> ')  %ptr
  %mask1 = trunc <WIDTH x MASK> %mask to <WIDTH x i1>
  %result = select <WIDTH x i1> %mask1, <WIDTH x i16> %new, <WIDTH x i16> %old
  store <WIDTH x i16> %result, <WIDTH x i16> * %ptr
  ret void
}

define void @__masked_store_blend_i32(<WIDTH x i32>* nocapture %ptr, <WIDTH x i32> %new, 
                                      <WIDTH x MASK> %mask) nounwind alwaysinline {
  %old = load PTR_OP_ARGS(`<WIDTH x i32> ')  %ptr
  %mask1 = trunc <WIDTH x MASK> %mask to <WIDTH x i1>
  %result = select <WIDTH x i1> %mask1, <WIDTH x i32> %new, <WIDTH x i32> %old
  store <WIDTH x i32> %result, <WIDTH x i32> * %ptr
  ret void
}

define void @__masked_store_blend_i64(<WIDTH x i64>* nocapture %ptr,
                            <WIDTH x i64> %new, <WIDTH x MASK> %mask) nounwind alwaysinline {
  %old = load PTR_OP_ARGS(`<WIDTH x i64> ')  %ptr
  %mask1 = trunc <WIDTH x MASK> %mask to <WIDTH x i1>
  %result = select <WIDTH x i1> %mask1, <WIDTH x i64> %new, <WIDTH x i64> %old
  store <WIDTH x i64> %result, <WIDTH x i64> * %ptr
  ret void
}

define i64 @__movmsk(<WIDTH x MASK> %mask) nounwind readnone alwaysinline {
  %mask1 = trunc <WIDTH x MASK> %mask to <WIDTH x i16>
  %res = bitcast <WIDTH x i16> %mask1 to i64
  ret i64 %res
}

define i128 @__movmsk128(<WIDTH x MASK> %mask) nounwind readnone alwaysinline {
  %mask_128 = bitcast <WIDTH x MASK> %mask to i128
  ret i128 %mask_128
}

define i1 @__any(<4 x MASK> %mask) nounwind readnone alwaysinline {
  entry:
    ; %mask1 = trunc <WIDTH x MASK> %mask to <WIDTH x i1>
    ; %mask_i4 = bitcast <WIDTH x i1> %mask1 to i4
    ; %cmp = icmp ne i4 %mask_i4, 0
    ; ret i1 %cmp
    ; %any_true = call i32 @llvm.wasm.anytrue.v4i32(<4 x i32> %mask)
    %any_true = bitcast <WIDTH x MASK> %mask to i128
    %cmp = icmp ne i128 %any_true, 0
    ret i1 %cmp
}

define i1 @__all(<WIDTH x MASK> %mask) nounwind readnone alwaysinline {
  entry:
    ; %mask1 = trunc <WIDTH x MASK> %mask to <WIDTH x i1>
    ; %mask_i4 = bitcast <WIDTH x i1> %mask1 to i4
    ; %cmp = icmp eq i4 %mask_i4, 15
    ; ret i1 %cmp
    ; %all_true = call i32 @llvm.wasm.alltrue.v4i32(<4 x i32> %mask)
    %all_true = bitcast <WIDTH x MASK> %mask to i128
    %cmp = icmp ne i128 %all_true, 1
    ret i1 %cmp
}

declare i32 @llvm.wasm.anytrue.v4i32(<4 x i32>)
declare i32 @llvm.wasm.alltrue.v4i32(<4 x i32>)

define i1 @__none(<WIDTH x MASK> %mask) nounwind readnone alwaysinline {
  %any = call i1 @__any(<WIDTH x MASK> %mask)
  %none = icmp eq i1 %any, 0
  ret i1 %none
}

gen_gather_factored(i8)
gen_gather_factored(i16)
gen_gather_factored(i32)
gen_gather_factored(float)
gen_gather_factored(i64)
gen_gather_factored(double)

masked_load(i8,  1)
masked_load(i16, 2)
masked_load(i32, 4)
masked_load(float, 4)
masked_load(i64, 8)
masked_load(double, 8)

gen_masked_store(i8)
gen_masked_store(i16)
gen_masked_store(i32)
gen_masked_store(i64)
masked_store_float_double()

gen_scatter(i8)
gen_scatter(i16)
gen_scatter(i32)
gen_scatter(float)
gen_scatter(i64)
gen_scatter(double)

packed_load_and_store(4)
define_prefetches()