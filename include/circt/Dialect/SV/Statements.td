//===- Statements.td - SV statements ops -------------------*- tablegen -*-===//
//
// This describes the ops for System Verilog statements.
//
//===----------------------------------------------------------------------===//

class HasCustomParserPrinter {
  code printer = [{ return ::print$cppClass(p, *this); }];
  code parser = [{ return ::parse$cppClass(parser, result); }];
}

def HasRegionTerminator : SingleBlockImplicitTerminator<"YieldOp">;

//===----------------------------------------------------------------------===//
// Control flow like-operations
//===----------------------------------------------------------------------===//

// TODO: MLIR Supports parsing/printing regions.  We should give it a try once
// this patch is merged in our tree:
// https://github.com/llvm/llvm-project/commit/eaeadce9bd11

def IfDefOp : SVOp<"ifdef", [HasRegionTerminator]>, HasCustomParserPrinter {
  let summary = "'ifdef MACRO' block";
   
   let description = [{
    This operation is an #ifdef block, or an #ifndef block if `string` starts
    with a `!` character.
    }];

  let regions = (region SizedRegion<1>:$body);
  let arguments = (ins StrAttr:$cond);
  let results = (outs);
  
  // TODO: ODS doesn't support parsing/printing regions yet :-(
  // let assemblyFormat = [{ $clock attr-dict $body }];*/

  // TODO: ODS forces using a custom builder just to get the region terminator
  // implicitly installed.
  let skipDefaultBuilders = 1;
  let builders = [
    OpBuilderDAG<(ins "StringRef":$cond)>
  ];

  let extraClassDeclaration = [{
    Block *getBodyBlock() { return &body().front(); }
  }];
}

def IfOp : SVOp<"if", [HasRegionTerminator]>,
           HasCustomParserPrinter {
  let summary = "'if (cond)' block";
  
  let regions = (region SizedRegion<1>:$body);
  let arguments = (ins I1:$cond);
  let results = (outs);
  
  // TODO: ODS doesn't support parsing/printing regions yet :-(
  //let assemblyFormat = [{ $cond attr-dict $body }];

  // TODO: ODS forces using a custom builder just to get the region terminator
  // implicitly installed.
  let skipDefaultBuilders = 1;
  let builders = [
    OpBuilderDAG<(ins "Value":$cond)>
  ];

  let extraClassDeclaration = [{
    Block *getBodyBlock() { return &body().front(); }
  }];
}

// TODO: This should be generalized, e.g. with an enum to specify the edge
// trigger behavior.
def AlwaysAtPosEdgeOp : SVOp<"alwaysat_posedge", [HasRegionTerminator]>,
                        HasCustomParserPrinter {
  let summary = "'always @(posedge ...)'' block";
  
  let regions = (region SizedRegion<1>:$body);
  let arguments = (ins I1:$clock);
  let results = (outs);
  
  // TODO: ODS doesn't support parsing/printing regions yet :-(
  //let assemblyFormat = [{ $clock attr-dict $body }];

  // TODO: ODS forces using a custom builder just to get the region terminator
  // implicitly installed.
  let skipDefaultBuilders = 1;
  let builders = [
    OpBuilderDAG<(ins "Value":$cond)>
  ];

  let extraClassDeclaration = [{
    Block *getBodyBlock() { return &body().front(); }
  }];
}

//===----------------------------------------------------------------------===//
// Other Statements
//===----------------------------------------------------------------------===//

def YieldOp
  : SVOp<"yield", [NoSideEffect, Terminator,
                   ParentOneOf<["IfDefOp, IfOp", "AlwaysAtPosEdgeOp"]>]> {
  let summary = "terminator for control-flow operation regions";
  let arguments = (ins);

   let assemblyFormat = [{attr-dict}];
}

// TODO: This needs to model the file descriptor to write on.  This is currently
// hard coded to 32'h80000002.
def FWriteOp : SVOp<"fwrite"> {
  let summary = "'$fwrite' statement";
   
  let arguments = (ins StrAttr:$string, Variadic<AnyType>:$operands);
  let results = (outs);

  let assemblyFormat = [{
    $string attr-dict (`(` $operands^ `)` `:` type($operands))?
  }];
}

def FinishOp : SVOp<"finish"> {
  let summary = "'$finish' statement";
  let description = [{
    Finishes a simulation and exits the simulation process.
  }];

  let arguments = (ins);
  let results = (outs);

  let assemblyFormat = [{ attr-dict }];
}

def FatalOp : SVOp<"fatal"> {
  let summary = "'$fatal' statement";
  let description = [{
    Run-time fatal assertion error.
  }];

  let arguments = (ins);
  let results = (outs);

  let assemblyFormat = [{ attr-dict }];
}

//===----------------------------------------------------------------------===//
// Verification Statements
//===----------------------------------------------------------------------===//

def AssertOp : SVOp<"assert"> {
  let summary = "immediate assertion statement";
  let description = [{
    Assert that a specific condition is always true.
  }];

  let arguments = (ins AnyType:$predicate);
  let results = (outs);

  let assemblyFormat = [{ attr-dict $predicate `:` type($predicate) }];
}

def AssumeOp : SVOp<"assume"> {
  let summary = "assume property statement";
  let description = [{
    Assume that a specific property is always true.
  }];

  let arguments = (ins AnyType:$property);
  let results = (outs);

  let assemblyFormat = [{ attr-dict $property `:` type($property) }];
}

def CoverOp : SVOp<"cover"> {
  let summary = "functional coverage statement";
  let description = [{
    Assert that a specific property happens during the course of execution.
  }];

  let arguments = (ins AnyType:$property);
  let results = (outs);

  let assemblyFormat = [{ attr-dict $property `:` type($property) }];
}
