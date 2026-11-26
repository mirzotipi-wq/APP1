// Independent receipt parser used by w069 in session V8; no build or CI execution.
export function parseCore(text) {
  const lines=text.split("\n"), release=lines.findIndex(x=>x.includes("swift test --configuration release"));
  const method=/Test Case '([^']+)' (passed|failed|skipped) \(/;
  const eventSet=part=>part.flatMap((text,i)=>{const m=text.match(method);return m?[{method:m[1],status:m[2]}]:[]});
  const debug=eventSet(lines.slice(0,release)), production=eventSet(lines.slice(release));
  const fixtures=lines.flatMap((text,i)=>{
    const m=text.match(/\/([^\/ ]+\.bin): mean=([\deE+.\-]+), max=(\d+), >4 fraction=([\deE+.\-]+), invalid=(\d+)\/(\d+), invalid-mask-mismatches=(\d+)(?:, max-limit=(\d+))?, (PASS|FAIL)/);
    return m?[{line:i+1,fixture:m[1],mean:+m[2],maximum:+m[3],outliers:+m[4],candidateInvalid:+m[5],referenceInvalid:+m[6],maskMismatches:+m[7],maximumLimit:m[8]?+m[8]:null,result:m[9]}]:[];
  });
  const stats=events=>({passed:events.filter(x=>x.status==="passed").length,failed:events.filter(x=>x.status==="failed").length,skipped:events.filter(x=>x.status==="skipped").length,uniquePassed:new Set(events.filter(x=>x.status==="passed").map(x=>x.method)).size});
  return {lineCount:lines.length,debug:stats(debug),release:stats(production),methods:[debug,production],fixtures,allFixturesPass:fixtures.length===14&&fixtures.every(x=>x.result==="PASS"&&x.mean<=1&&x.outliers<=0.005&&x.maskMismatches===0&&x.candidateInvalid===x.referenceInvalid&&(x.maximumLimit===null||x.maximum<=1))};
}
export function parseNative(text) {
  const lines=text.split("\n");
  const events=lines.flatMap((text,i)=>{const m=text.match(/Test Case '-\[KeyAndFillTests\.([^ ]+) ([^\]]+)\]' (passed|failed|skipped) \(/);return m?[{line:i+1,method:m[1]+"/"+m[2],status:m[3]}]:[]});
  const fixtures=lines.flatMap((text,i)=>{const m=text.match(/Metal (precision )?([^:]+): mean ([\deE+.\-]+), max (\d+), outliers ([\deE+.\-]+), (mask|invalid match) (true|false)/);return m?[{line:i+1,kind:m[1]?"strict":"canonical",fixture:m[2],mean:+m[3],maximum:+m[4],outliers:+m[5],maskPrinted:m[6],printedTrue:m[7]==="true"}]:[]});
  return {lineCount:lines.length,passed:events.filter(x=>x.status==="passed").length,failed:events.filter(x=>x.status==="failed").length,skipped:events.filter(x=>x.status==="skipped").length,uniquePassed:new Set(events.filter(x=>x.status==="passed").map(x=>x.method)).size,fixtures,metalRequiredPassed:events.filter(x=>["StudyRendererTests/testMetalMatchesCPUOnAvailableDevice","StudyRendererTests/testMetalRawDispatchRejectsInvalidPackedMetadata","StudyPrecisionMatrixTests/testMetalMatchesCPUForEightRequiredPrecisionFixtures"].includes(x.method)),testExecuteSucceeded:lines.some(x=>x.includes("** TEST EXECUTE SUCCEEDED **")),noSkipsVerification:lines.some(x=>x.includes("Required Metal methods executed and passed; no native methods skipped."))};
}
