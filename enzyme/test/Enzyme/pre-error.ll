; RUN: %opt < %s %loadEnzyme -enzyme -enzyme_preopt=false -mem2reg -instsimplify -adce -loop-deletion -correlated-propagation -simplifycfg -S | FileCheck %s

source_filename = "/mnt/Data/git/Enzyme/enzyme/test/Integration/eigensumsqdyn.cpp"
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @__enzyme_autodiff(...)

define i32 @caller(double* %A, double* %Ap, i64* %B, i64* %Bp) {
  %call = call double (...) @__enzyme_autodiff(i8* bitcast (double (double*, i64*)* @matvec to i8*), double* %A, double* %Ap, i64* %B)
  ret i32 0
}

; Function Attrs: noinline nounwind uwtable
define internal double @matvec(double* %place, i64* %m_rows) {
entry:
  call void @subfn(double* %place, i64* nonnull %m_rows)
  %r1 = load double, double* %place, align 8, !tbaa !2
  %c2 = load i64, i64* %m_rows, align 8, !tbaa !6
  %cmp64.i.i = icmp sgt i64 %c2, 1
  br i1 %cmp64.i.i, label %for.body.i.i, label %exit

for.body.i.i:                                     ; preds = %entry
  %arrayidx.i.i45.i.i = getelementptr inbounds double, double* %place, i64 1
  %z3 = load double, double* %arrayidx.i.i45.i.i, align 8, !tbaa !2
  %add.i42.i.i = fadd double %r1, %z3
  store double %add.i42.i.i, double* %arrayidx.i.i45.i.i
  br label %exit

exit:                                             ; preds = %for.body.i.i, %entry
  %res.0.lcssa.i.i = phi double [ %r1, %entry ], [ %add.i42.i.i, %for.body.i.i ]
  ret double %res.0.lcssa.i.i
}

define linkonce_odr dso_local void @subfn(double* %place, i64* %m_rows) {
entry:
  %rows = load i64, i64* %m_rows, align 8
  br label %for1

for1:                                             ; preds = %end2, %entry
  %i = phi i64 [ 0, %entry ], [ %nexti, %end2 ]
  %nexti = add nuw nsw i64 %i, 1
  br label %for2

for2:                                             ; preds = %for2, %for1
  %j = phi i64 [ %nextj, %for2 ], [ 1, %for1 ]
  %res = phi double [ %add, %for2 ], [ 0.000000e+00, %for1 ]
  %nextj = add nuw nsw i64 %j, 1
  %arrayidx = getelementptr inbounds double, double* %place, i64 %j
  %loaded = load double, double* %arrayidx, align 8, !tbaa !2
  %mul = fmul double %loaded, 2.000000e+00
  %add = fadd double %res, %mul
  %cond2 = icmp eq i64 %nextj, %rows
  br i1 %cond2, label %end2, label %for2

end2:                                             ; preds = %for2
  %tostore = getelementptr inbounds double, double* %place, i64 %i
  store double %add, double* %tostore, align 8, !tbaa !2
  %cond1 = icmp eq i64 %nexti, 4
  br i1 %cond1, label %exit, label %for1

exit:                                             ; preds = %end2
  ret void
}

!llvm.module.flags = !{!0}
!llvm.ident = !{!1}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{!"clang version 7.1.0 "}
!2 = !{!3, !3, i64 0}
!3 = !{!"double", !4, i64 0}
!4 = !{!"omnipotent char", !5, i64 0}
!5 = !{!"Simple C++ TBAA"}
!6 = !{!7, !9, i64 8}
!7 = !{!"_ZTSN5Eigen12DenseStorageIdLin1ELin1ELin1ELi0EEE", !8, i64 0, !9, i64 8, !9, i64 16}
!8 = !{!"any pointer", !4, i64 0}
!9 = !{!"long", !4, i64 0}

; CHECK: define internal { { i64, double* } } @augmented_subfn(double* %place, double* %"place'", i64* %m_rows) {
; CHECK-NEXT: entry:
; CHECK-NEXT:   %0 = alloca { { i64, double* } }
; CHECK-NEXT:   %1 = getelementptr { { i64, double* } }, { { i64, double* } }* %0, i32 0, i32 0
; CHECK-NEXT:   %rows = load i64, i64* %m_rows, align 8
; CHECK-NEXT:   %2 = getelementptr { i64, double* }, { i64, double* }* %1, i32 0, i32 0
; CHECK-NEXT:   store i64 %rows, i64* %2
; CHECK-NEXT:   %3 = add i64 %rows, -2
; CHECK-NEXT:   %4 = add nuw i64 %3, 1
; CHECK-NEXT:   %5 = mul nuw i64 %4, 4
; CHECK-NEXT:   %mallocsize = mul i64 %5, 8
; CHECK-NEXT:   %malloccall = tail call noalias nonnull i8* @malloc(i64 %mallocsize)
; CHECK-NEXT:   %loaded_malloccache = bitcast i8* %malloccall to double*
; CHECK-NEXT:   %6 = getelementptr { i64, double* }, { i64, double* }* %1, i32 0, i32 1
; CHECK-NEXT:   store double* %loaded_malloccache, double** %6
; CHECK-NEXT:   br label %for1

; CHECK: for1:                                             ; preds = %end2, %entry
; CHECK-NEXT:   %iv = phi i64 [ %iv.next, %end2 ], [ 0, %entry ]
; CHECK-NEXT:   %iv.next = add nuw i64 %iv, 1
; CHECK-NEXT:   br label %for2

; CHECK: for2:                                             ; preds = %for2, %for1
; CHECK-NEXT:   %iv1 = phi i64 [ %iv.next2, %for2 ], [ 0, %for1 ]
; CHECK-NEXT:   %res = phi double [ %add, %for2 ], [ 0.000000e+00, %for1 ]
; CHECK-NEXT:   %iv.next2 = add nuw i64 %iv1, 1
; CHECK-NEXT:   %nextj = add nuw nsw i64 %iv.next2, 1
; CHECK-NEXT:   %arrayidx = getelementptr inbounds double, double* %place, i64 %iv.next2
; CHECK-NEXT:   %loaded = load double, double* %arrayidx, align 8, !tbaa !2
; CHECK-NEXT:   %7 = mul nuw i64 %iv1, 4
; CHECK-NEXT:   %8 = add nuw i64 %iv, %7
; CHECK-NEXT:   %9 = getelementptr inbounds double, double* %loaded_malloccache, i64 %8
; CHECK-NEXT:   store double %loaded, double* %9, align 8, !invariant.group !10
; CHECK-NEXT:   %mul = fmul double %loaded, 2.000000e+00
; CHECK-NEXT:   %add = fadd double %res, %mul
; CHECK-NEXT:   %cond2 = icmp eq i64 %nextj, %rows
; CHECK-NEXT:   br i1 %cond2, label %end2, label %for2

; CHECK: end2:                                             ; preds = %for2
; CHECK-NEXT:   %tostore = getelementptr inbounds double, double* %place, i64 %iv
; CHECK-NEXT:   store double %add, double* %tostore, align 8, !tbaa !2
; CHECK-NEXT:   %cond1 = icmp eq i64 %iv.next, 4
; CHECK-NEXT:   br i1 %cond1, label %exit, label %for1

; CHECK: exit:                                             ; preds = %end2
; CHECK-NEXT:   %10 = load { { i64, double* } }, { { i64, double* } }* %0
; CHECK-NEXT:   ret { { i64, double* } } %10
; CHECK-NEXT: }

; CHECK: define internal {} @diffesubfn(double* %place, double* %"place'", i64* %m_rows, { i64, double* } %tapeArg) {
; CHECK-NEXT: entry:
; CHECK-NEXT:   %0 = extractvalue { i64, double* } %tapeArg, 1
; CHECK-NEXT:   %rows = extractvalue { i64, double* } %tapeArg, 0
; CHECK-NEXT:   br label %invertend2

; CHECK: invertentry:                                      ; preds = %invertfor1
; CHECK-NEXT:   %1 = bitcast double* %0 to i8*
; CHECK-NEXT:   tail call void @free(i8* nonnull %1)
; CHECK-NEXT:   ret {} undef

; CHECK: invertfor1:                                       ; preds = %invertfor2
; CHECK-NEXT:   %2 = icmp eq i64 %"iv'ac.0", 0
; CHECK-NEXT:   br i1 %2, label %invertentry, label %incinvertfor1

; CHECK: incinvertfor1:                                    ; preds = %invertfor1
; CHECK-NEXT:   %3 = sub nuw nsw i64 %"iv'ac.0", 1
; CHECK-NEXT:   br label %invertend2

; CHECK: invertfor2:                                       ; preds = %invertend2, %incinvertfor2
; CHECK-NEXT:   %"iv1'ac.0" = phi i64 [ %_unwrap, %invertend2 ], [ %8, %incinvertfor2 ]
; CHECK-NEXT:   %m0diffeloaded = fmul fast double %10, 2.000000e+00
; CHECK-NEXT:   %iv.next2_unwrap = add nuw i64 %"iv1'ac.0", 1
; CHECK-NEXT:   %"arrayidx'ipg" = getelementptr inbounds double, double* %"place'", i64 %iv.next2_unwrap
; CHECK-NEXT:   %4 = load double, double* %"arrayidx'ipg", align 8
; CHECK-NEXT:   %5 = fadd fast double %4, %m0diffeloaded
; CHECK-NEXT:   store double %5, double* %"arrayidx'ipg", align 8
; CHECK-NEXT:   %6 = icmp eq i64 %"iv1'ac.0", 0
; CHECK-NEXT:   %7 = select i1 %6, double 0.000000e+00, double %10
; CHECK-NEXT:   br i1 %6, label %invertfor1, label %incinvertfor2

; CHECK: incinvertfor2:                                    ; preds = %invertfor2
; CHECK-NEXT:   %8 = sub nuw nsw i64 %"iv1'ac.0", 1
; CHECK-NEXT:   br label %invertfor2

; CHECK: invertend2:                                       ; preds = %entry, %incinvertfor1
; CHECK-NEXT:   %"add'de.1" = phi double [ 0.000000e+00, %entry ], [ 0.000000e+00, %incinvertfor1 ]
; CHECK-NEXT:   %"iv'ac.0" = phi i64 [ 3, %entry ], [ %3, %incinvertfor1 ]
; CHECK-NEXT:   %"tostore'ipg" = getelementptr inbounds double, double* %"place'", i64 %"iv'ac.0"
; CHECK-NEXT:   %9 = load double, double* %"tostore'ipg", align 8
; CHECK-NEXT:   %"tostore'ipg3" = getelementptr inbounds double, double* %"place'", i64 %"iv'ac.0"
; CHECK-NEXT:   store double 0.000000e+00, double* %"tostore'ipg3", align 8
; CHECK-NEXT:   %10 = fadd fast double %"add'de.1", %9
; CHECK-NEXT:   %rows_unwrap = extractvalue { i64, double* } %tapeArg, 0
; CHECK-NEXT:   %_unwrap = add i64 %rows_unwrap, -2
; CHECK-NEXT:   br label %invertfor2
; CHECK-NEXT: }