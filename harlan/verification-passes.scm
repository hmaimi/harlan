(library
  (harlan verification-passes)
  (export
    verify-harlan
    verify-nest-lets
    verify-parse-harlan
    verify-flatten-lets
    verify-returnify
    verify-make-kernel-dimensions-explicit
    verify-lift-complex
    verify-typecheck
    verify-expand-primitives
    verify-lower-vectors
    verify-returnify-kernels
    verify-make-vector-refs-explicit
    verify-remove-nested-kernels
    verify-uglify-vectors
    verify-annotate-free-vars
    verify-hoist-kernels
    verify-generate-kernel-calls
    verify-compile-module
    verify-convert-types
    verify-compile-kernels
    verify-print-c)
  (import
    (rnrs)
    (harlan helpers)
    (elegant-weapons helpers)
    (util verify-grammar))

(grammar-transforms

  (%static
    (Ret-Stmt (return Expr) (return))
    (Type
      harlan-type
      (vec Integer Type)
      (ptr Type)
      ((Type *) -> Type))
    (C-Type
      harlan-c-type
      harlan-cl-type
      (ptr C-Type)
      (const-ptr C-Type)
      ((C-Type *) -> C-Type)
      Type)
    (Var ident)
    (Integer integer)
    (Reduceop reduceop)
    (Binop binop)
    (Relop relop)
    (Float float)
    (String string)
    (Char char)
    (Boolean boolean)
    (Number number))
  
  (harlan
    (Start Module)
    (Module (module Decl +))
    (Decl
      (extern Var (Type *) -> Type)
      (fn Var (Var *) Value +) ;; depricated, use define instead
      (define (Var Var *) Value +))
    (Value
      char
      integer
      boolean
      float
      string
      ident
      (let Var Value)
      (let ((Var Value) *) Value +)
      (begin Value * Value)
      (print Value)
      (print Value Value)
      (write-pgm Value Value)
      (assert Value)
      (set! Value Value)
      (vector-set! Value Value Value)
      (for (Var Value Value) Value +)
      (while Value Value +)
      (if Value Value)
      (if Value Value Value)
      (return)
      (return Value)
      (var Var) ;; depricated, vars do not need tags
      (vector Value +)
      (vector-ref Value Value)
      (kernel ((Var Value) +) Value * Value)
      (reduce Reduceop Value)
      (iota Value)
      (length Value)
      (make-vector Integer Value)
      (Binop Value Value)
      (Relop Value Value)
      (Var Value *)))

  (nest-lets (%inherits Module Decl)
    (Start Module)
    (Value
      char
      integer
      boolean
      float
      string
      ident
      (let ((Var Value) *) Value +)
      (begin Value * Value)
      (print Value)
      (print Value Value)
      (write-pgm Value Value)
      (assert Value)
      (set! Value Value)
      (vector-set! Value Value Value)
      (for (Var Value Value) Value +)
      (while Value Value +)
      (if Value Value)
      (if Value Value Value)
      (return Value)
      (var Var)
      (vector Value +)
      (vector-ref Value Value)
      (kernel ((Var Value) +) Value +)
      (reduce Reduceop Value)
      (iota Value)
      (length Value)
      (make-vector Integer Value)
      (Binop Value Value)
      (Relop Value Value)
      (Var Value *)))

  (parse-harlan (%inherits Module)
    (Start Module)
    (Decl
      (extern Var (Type *) -> Type)
      (fn Var (Var *) Stmt))
    (Stmt
      (let ((Var Expr) *) Stmt)
      (if Expr Stmt)
      (if Expr Stmt Stmt)
      (begin Stmt * Stmt)
      (print Expr)
      (print Expr Expr)
      (write-pgm Expr Expr)
      (assert Expr)
      (set! Expr Expr)
      (vector-set! Expr Expr Expr)
      (do Expr)
      (for (Var Expr Expr) Stmt)
      (while Expr Stmt)
      (return)
      (return Expr))
    (Expr
      (char Char)
      (num Integer)
      (float Float)
      (str String)
      (bool Boolean)
      (var Var)
      (vector Expr +)
      (begin Stmt * Expr)
      (if Expr Expr Expr)
      (vector-ref Expr Expr)
      (let ((Var Expr) *) Expr)
      (kernel ((Var Expr) +) Expr)
      (reduce Reduceop Expr)
      (iota (num Integer))
      (iota (length Expr))
      (length Expr)
      (int->float Expr)
      (make-vector (num Integer))
      (Binop Expr Expr)
      (Relop Expr Expr)
      (call Var Expr *)))

  (returnify (%inherits Module)
    (Start Module)
    (Decl
      (fn Var (Var *) Body)
      (extern Var (Type *) -> Type))
    (Body
      (begin Stmt * Body)
      (let ((Var Expr) *) Body)
      (if Expr Body)
      (if Expr Body Body)
      Ret-Stmt)
    (Stmt
      (let ((Var Expr) *) Stmt)
      (if Expr Stmt)
      (if Expr Stmt Stmt)
      (begin Stmt * Stmt)
      (print Expr)
      (print Expr Expr)
      (write-pgm Expr Expr)
      (assert Expr)
      (set! Expr Expr)
      (vector-set! Expr Expr Expr)
      (do Expr)
      (for (Var Expr Expr) Stmt)
      (while Expr Stmt)
      Ret-Stmt)
    (Expr
      (char Char)
      (bool Boolean)
      (num Integer)
      (float Float)
      (str String)
      (var Var)
      (vector Expr +)
      (begin Stmt * Expr)
      (if Expr Expr Expr)
      (vector-ref Expr Expr)
      (let ((Var Expr) *) Expr)
      (kernel ((Var Expr) +) Expr)
      (reduce Reduceop Expr)
      (iota (num Integer))
      (iota (length Expr))
      (length Expr)
      (int->float Expr)
      (make-vector (num Integer))
      (Binop Expr Expr)
      (Relop Expr Expr)
      (call Var Expr *)))

  (typecheck (%inherits Module)
    (Start Module)
    (Decl
      (extern Var (Type *) -> Type)
      (fn Var (Var *) Type Body))
    (Body
      (begin Stmt * Body)
      (let ((Var Type Expr) *) Body)
      (if Expr Body)
      (if Expr Body Body)
      Ret-Stmt)
    (Stmt
      (let ((Var Type Expr) *) Stmt)
      (if Expr Stmt)
      (begin Stmt * Stmt)
      (if Expr Stmt Stmt)
      (print Type Expr)
      (print Type Expr Expr)
      (write-pgm Expr Expr)
      (assert Expr)
      (set! Expr Expr)
      (vector-set! Type Expr Expr Expr)
      (do Expr)
      (for (Var Expr Expr) Stmt)
      (while Expr Stmt)
      (return Expr))
    (Expr
      (char Char)
      (int Integer)
      (u64 Number)
      (float Float)
      (str String)
      (bool Boolean)
      (var Type Var)
      (if Expr Expr Expr)
      (let ((Var Type Expr) *) Expr)
      (begin Stmt * Expr)
      (vector Type Expr +)
      (vector-ref Type Expr Expr)
      (kernel Type (((Var Type) (Expr Type)) +) Expr)
      (reduce Type Reduceop Expr)
      (iota (int Integer))
      (length Expr)
      (int->float Expr)
      (make-vector Type (int Integer))
      (Binop Type Expr Expr)
      (Relop Type Expr Expr)
      (call Expr Expr *)))

  (expand-primitives
   (%inherits Module Decl Body)
   (Start Module)
   (Stmt
     (let ((Var Type Expr) *) Stmt)
     (if Expr Stmt)
     (begin Stmt * Stmt)
     (if Expr Stmt Stmt)
     (print Expr)
     (print Expr Expr)
     (assert Expr)
     (set! Expr Expr)
     (vector-set! Type Expr Expr Expr)
     (do Expr)
     (for (Var Expr Expr) Stmt)
     (while Expr Stmt)
     (return Expr))
    (Expr
      (char Char)
      (int Integer)
      (u64 Number)
      (float Float)
      (str String)
      (bool Boolean)
      (var Type Var)
      (if Expr Expr Expr)
      (let ((Var Type Expr) *) Expr)
      (begin Stmt * Expr)
      (vector Type Expr +)
      (vector-ref Type Expr Expr)
      (kernel Type (((Var Type) (Expr Type)) +) Expr)
      (reduce Type Reduceop Expr)
      (iota (int Integer))
      (length Expr)
      (int->float Expr)
      (make-vector Type (int Integer))
      (Binop Expr Expr)
      (Relop Expr Expr)
      (call Expr Expr *)))
  
  (make-kernel-dimensions-explicit
   (%inherits Module Decl Body Stmt)
   (Start Module)
   (Expr
      (char Char)
      (int Integer)
      (u64 Number)
      (float Float)
      (str String)
      (bool Boolean)
      (var Type Var)
      (if Expr Expr Expr)
      (let ((Var Type Expr) *) Expr)
      (begin Stmt * Expr)
      (vector Type Expr +)
      (vector-ref Type Expr Expr)
      (kernel Type (Integer +) (((Var Type) (Expr Type) Integer) +) Expr)
      (reduce Type Reduceop Expr)
      (iota (int Integer))
      (length Expr)
      (int->float Expr)
      (make-vector Type (int Integer))
      (Binop Expr Expr)
      (Relop Expr Expr)
      (call Expr Expr *)))
  
  (lift-complex (%inherits Module Decl)
    (Start Module)
    (Body
      (begin Stmt * Body)
      (let ((Var Type Let-Expr) *) Body)
      (if Expr Body)
      (if Expr Body Body)
      Ret-Stmt)      
    (Stmt
      (let ((Var Type Let-Expr) *) Stmt)
      (if Expr Stmt)
      (if Expr Stmt Stmt)
      (begin Stmt * Stmt)
      (print Expr)
      (print Expr Expr)
      (assert Expr)
      (set! Expr Expr)
      (vector-set! Type Expr Expr Expr)
      (do Expr)
      (for (Var Expr Expr) Stmt)
      (while Expr Stmt)
      Ret-Stmt)
    (Let-Expr
      (begin Stmt * Let-Expr)
      (let ((Var Type Let-Expr) *) Let-Expr)
      (kernel Type (Integer +) (((Var Type) (Expr Type) Integer) +) Let-Expr)
      (vector Type Let-Expr +)
      (reduce Type Reduceop Let-Expr)
      (make-vector Type (int Integer))
      (iota (int Integer))
      Expr)
    (Expr
      (char Char)
      (int Integer)
      (u64 Number)
      (float Float)
      (str String)
      (bool Boolean)
      (var Type Var)
      (int->float Expr)
      (length Expr)
      (if Expr Expr Expr)
      (let ((Var Type Let-Expr) *) Expr)
      (call Expr Expr *)
      (vector-ref Type Expr Expr)
      (Binop Expr Expr)
      (Relop Expr Expr)))

  (remove-nested-kernels
    (%inherits Module Decl Expr Stmt Body Let-Expr)
    (Start Module))

  (returnify-kernels (%inherits Module Decl Expr Body)
    (Start Module)
    (Stmt
      (print Expr)
      (print Expr Expr)
      (assert Expr)
      (set! Expr Expr)
      (vector-set! Type Expr Expr Expr)
      (kernel Type (Integer +) (((Var Type) (Expr Type) Integer) +) Stmt)
      (let ((Var Type Let-Expr) *) Stmt)
      (if Expr Stmt)
      (if Expr Stmt Stmt)
      (for (Var Expr Expr) Stmt)
      (while Expr Stmt)
      (do Expr)
      (begin Stmt * Stmt)
      Ret-Stmt)
    (Let-Expr
      (let ((Var Type Let-Expr) *) Let-Expr)
      (vector Type Let-Expr +)
      (reduce Type Reduceop Let-Expr)
      (make-vector Type (int Integer))
      (iota (int Integer))
      Expr))

  (make-vector-refs-explicit (%inherits Module Decl Body Stmt Let-Expr)
    (Start Module)
    (Expr
      (bool Boolean)
      (char Char)
      (int Integer)
      (u64 Number)
      (float Float)
      (str String)
      (var Type Var)
      (int->float Expr)
      (length Expr)
      (addressof Expr)
      (deref Expr)
      (if Expr Expr Expr)
      (let ((Var Let-Expr) *) Expr)
      (call Expr Expr *)
      (c-expr C-Type Var)
      (vector-ref Type Expr Expr)
      (Binop Expr Expr)
      (Relop Expr Expr)))

  (lower-vectors (%inherits Module Decl Body)
    (Start Module)
    (Stmt 
      (print Expr)
      (print Expr Expr)
      (assert Expr)
      (set! Expr Expr)
      (vector-set! Type Expr Expr Expr)
      (kernel Type (Integer +) (((Var Type) (Expr Type) Integer) +) Stmt)
      (let ((Var Type Let-Expr) *) Stmt)
      (begin Stmt * Stmt)
      (if Expr Stmt)
      (if Expr Stmt Stmt)
      (for (Var Expr Expr) Stmt)
      (while Expr Stmt)
      (do Expr)
      Ret-Stmt)
    (Let-Expr
      (let ((Var Type Let-Expr) *) Let-Expr)
      (make-vector Type (int Integer))
      Expr)
    (Expr
      (char Char)
      (int Integer)
      (u64 Number)
      (float Float)
      (int->float Expr)
      (bool Boolean)
      (str String)
      (var Type Var)
      (let ((Var Type Let-Expr) *) Expr)
      (if Expr Expr Expr)
      (call Expr Expr *)
      (c-expr C-Type Var)
      (vector-ref Type Expr Expr)
      (length Expr)
      (addressof Expr)
      (deref Expr)
      (Relop Expr Expr)
      (Binop Expr Expr)))

  (uglify-vectors (%inherits Module)
    (Start Module)
    (Decl
     (extern Var (Type *) -> Type)
     (global Var Type Expr)
     (fn Var (Var *) Type Body))
    (Body
      (begin Stmt * Body)
      (let ((Var Type Expr) *) Body)
      (if Expr Body)
      (if Expr Body Body)
      Ret-Stmt)
    (Stmt
      (print Expr)
      (print Expr Expr)
      (assert Expr)
      (set! Expr Expr)
      (kernel (Integer +) (((Var Type) (Expr Type) Integer) +) Stmt)
      (let ((Var Type Expr) *) Stmt)
      (if Expr Stmt)
      (if Expr Stmt Stmt)
      (for (Var Expr Expr) Stmt)
      (while Expr Stmt)
      (do Expr)
      (begin Stmt +)
      Ret-Stmt)
    (Expr
      (bool Boolean)
      (char Char)
      (int Integer)
      (u64 Number)
      (str String)
      (float Float)
      (var Type Var)
      (c-expr Type Var)
      (let ((Var Type Expr) *) Expr)
      (if Expr Expr Expr)
      (call Expr Expr *)
      (cast Type Expr)
      (sizeof Type)
      (addressof Expr)
      (deref Expr)
      (vector-ref Type Expr Expr)
      (length Expr)
      (Relop Expr Expr)
      (Binop Expr Expr)))

  (annotate-free-vars (%inherits Module Decl Expr Body)
    (Start Module)
    (Stmt 
      (print Expr)
      (print Expr Expr)
      (assert Expr)
      (set! Expr Expr)
      (kernel (Integer +) (((Var Type) (Expr Type) Integer) +)
        (free-vars (Var Type) *)
        Stmt)
      (let ((Var Type Expr) *) Stmt)
      (begin Stmt * Stmt)
      (if Expr Stmt)
      (if Expr Stmt Stmt)
      (for (Var Expr Expr) Stmt)
      (while Expr Stmt)
      (do Expr)
      Ret-Stmt))

  (flatten-lets (%inherits Module Decl)
    (Start Module)
    (Body
      (begin Stmt * Body)
      (if Expr Body)
      (if Expr Body Body)
      Ret-Stmt)
    (Stmt
      (print Expr)
      (print Expr Expr)
      (assert Expr)
      (set! Expr Expr)
      (kernel (Integer +)
       (((Var Type) (Expr Type) Integer) +)
       (free-vars (Var Type) *) Stmt)
      (let Var Type Expr)
      (if Expr Stmt)
      (if Expr Stmt Stmt)
      (for (Var Expr Expr) Stmt)
      (while Expr Stmt)
      (do Expr)
      (begin Stmt +)
      Ret-Stmt)
    (Expr
      (bool Boolean)
      (char Char)
      (int Integer)
      (u64 Number)
      (str String)
      (float Float)
      (var Type Var)
      (c-expr Type Var)
      (if Expr Expr Expr)
      (call Expr Expr *)
      (cast Type Expr)
      (sizeof Type)
      (addressof Expr)
      (deref Expr)
      (vector-ref Type Expr Expr)
      (length Expr)
      (Relop Expr Expr)
      (Binop Expr Expr)))

  (hoist-kernels (%inherits Module Body)
    (Start Module)
    (Decl
      (gpu-module Kernel *)
      (fn Var (Var *) ((Type *) -> Type) Body)
      (global Var Type Expr)
      (extern Var (Type *) -> Type))
    (Kernel
      (kernel Var ((Var Type) +) Stmt))
    (Stmt 
      (print Expr)
      (print Expr Expr)
      (assert Expr)
      (set! Expr Expr)
      (apply-kernel Var Expr +)
      (let Var Type Expr)
      (begin Stmt * Stmt)
      (if Expr Stmt)
      (if Expr Stmt Stmt)
      (for (Var Expr Expr) Stmt)
      (while Expr Stmt)
      (do Expr)
      Ret-Stmt)
    (Expr
      (bool Boolean)
      (char Char)
      (int Integer)
      (u64 Number)
      (str String)
      (float Float)
      (var Type Var)
      (var C-Type Var)
      (c-expr C-Type Var)
      (if Expr Expr Expr)
      (field (var C-Type Var) Var)
      (deref Expr)
      (call Expr Expr *)
      (cast Type Expr)
      (sizeof Type)
      (addressof Expr)
      (vector-ref Type Expr Expr)
      (Relop Expr Expr)
      (Binop Expr Expr)))

  (generate-kernel-calls
    (%inherits Module Kernel Decl Expr Body)
    (Start Module)
    (Stmt
      (print Expr)
      (print Expr Expr)
      (assert Expr)
      (set! Expr Expr)
      (let Var C-Type Expr)
      (begin Stmt * Stmt)
      (if Expr Stmt)
      (if Expr Stmt Stmt)
      (for (Var Expr Expr) Stmt)
      (while Expr Stmt)
      (do Expr)
      Ret-Stmt))

  (compile-module
    (%inherits Kernel Body)
    (Start Module)
    (Module (Decl *))
    (Decl
      (include String)
      (gpu-module Kernel *)
      (func Type Var ((Var Type) *) Body)
      (global Var Type Expr)
      (extern Type Var (Type *)))
    (Stmt
      (print Expr)
      (print Expr Expr)
      (set! Expr Expr)
      (if Expr Stmt)
      (if Expr Stmt Stmt)
      (let Var C-Type Expr)
      (begin Stmt * Stmt)
      (for (Var Expr Expr) Stmt)
      (while Expr Stmt)
      (do Expr)
      Ret-Stmt)
    (Expr
      (bool Boolean)
      (char Char)
      (int Integer)
      (u64 Number)
      (str String)
      (float Float)
      (var Var)
      (c-expr C-Type Var)
      (deref Expr)
      (field Var +)
      (field Var + Type)
      (call Expr Expr *)
      (assert Expr)
      (cast Type Expr)
      (if Expr Expr Expr)
      (sizeof Type)
      (addressof Expr)
      (vector-ref Expr Expr)
      (Relop Expr Expr)
      (Binop Expr Expr)))

  (convert-types (%inherits Module Stmt Body)
    (Start Module)
    (Decl
      (include String)
      (gpu-module Kernel *)
      (func C-Type Var ((Var C-Type) *) Body)
      (global C-Type Var Expr)
      (extern C-Type Var (C-Type *))) 
    (Kernel
      (kernel Var ((Var C-Type) +) Stmt))
    (Expr
      (bool Boolean)
      (char Char)
      (int Integer)
      (u64 Number)
      (str String)
      (float Float)
      (var Var)
      (c-expr C-Type Var)
      (deref Expr)
      (field Var +)
      (field Var + C-Type)
      (call Expr Expr *)
      (assert Expr)
      (if Expr Expr Expr)
      (cast C-Type Expr)
      (sizeof C-Type)
      (addressof Expr)
      (vector-ref Expr Expr)
      (Relop Expr Expr)
      (Binop Expr Expr)))

  (compile-kernels
    (%inherits Module Body Stmt Expr)
    (Start Module)
    (Decl
      (include String)
      (func C-Type Var ((Var C-Type) *) Body)
      (global C-Type Var Expr)
      (extern C-Type Var (C-Type *))))

  (print-c
    (Start Module)
    (Module (Decl *))
    (Decl
      (include String)
      (global C-Type Var Expr *)
      (func C-Type Var ((Var C-Type) *) Body)
      (extern C-Type Var (C-Type *)))
    (Body
      (return Expr)
      (begin Stmt * Body)
      (if Expr Body)
      (if Expr Body Body))
    (Stmt
      (begin Stmt * Stmt)
      (let Var C-Type Expr)
      (if Expr Stmt)
      (if Expr Stmt Stmt)
      (return Expr)
      (print Expr)
      (print Expr Expr)
      (set! Expr Expr)
      (while Expr Stmt)
      (for (Var Expr Expr) Stmt)
      (do Expr))
    (Expr
      (bool Boolean)
      (int Integer)
      (u64 Number)
      (str String)
      (float Float)
      (var Var)
      (c-expr Type Var)
      (field Var +)
      (field Var + C-Type)
      (deref Expr)
      (assert Expr)
      (call Expr Expr *)
      (if Expr Expr Expr)
      (cast C-Type Expr)
      (sizeof C-Type)
      (addressof Expr)
      (vector-ref Expr Expr)
      (Relop Expr Expr)
      (Binop Expr Expr)))

  )
)