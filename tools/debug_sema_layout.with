// Prints the native field layout around an offset in Sema. This is a
// debugger companion: pass the byte offset reported by lldb to identify the
// exact field whose runtime header or payload is corrupt.

use Lexer
use Token
use Ast
use render
use Resolve
use Parser
use InternPool
use Diagnostic
use Source
use Sema
use Mir
use CiIR
use CImport
use compiler.Compilation
use ComptimeEval
use ComptimeValue
use ConanClient
use LockFile
use Fmt
use Lsp
use CiPrint
use CiMigrate
use BuildGraphKinds
use BuildGraphModel
use BuildGraphMaterialize
use BuildGraphDispatch
use BuildGraphOps
use BuildGraphSupport
use BuildGraphTools
use BuildGraphTests
use InitTemplates
use BuildGraphRuntime
use BuildGraphCache
use compiler.DriverOptions
use Analysis
use ReceiverMigration

fn main:
    let target: i64 = 792
    comptime for field in Sema.fields():
        if field.offset as i64 <= target and target < (field.offset + field.size) as i64:
            print(field.name ++ ": offset=" ++ f"{field.offset}" ++ " size=" ++ f"{field.size}" ++ " type=" ++ field.type_name)
