import hashlib
import json
from pathlib import Path
import subprocess

work = Path(__file__).resolve().parents[1]
out = work / 'private-output'
baseline = '58b3ca43943e18d0fc7800189b08365f424d9c9e'
snapshot = '1b286885cb803ba17e159713651515ab119e17f1'
def git(*args):
    return subprocess.check_output(['git', '-C', str(work), *args])

head = git('rev-parse', 'HEAD').decode().strip()
solver_path = 'Sources/LightingCore/LightOutputAdjustment.swift'
model_path = 'Sources/LightingCore/Scene.swift'
files = {}
for path in (solver_path, model_path):
    current = (work / path).read_bytes()
    assert current == git('show', f'{baseline}:{path}')
    assert current == git('show', f'{snapshot}:{path}')
    files[path] = {'sha256': hashlib.sha256(current).hexdigest(),
                   'identical_to_production_baseline_and_snapshot': True}

solver = (work / solver_path).read_text()
model = (work / model_path).read_text()
quality = (work / 'docs/QUALITY.md').read_text()
requirements = {
    'validated_source_before_zero_or_positive_solve':
        'guard source.isValid else { throw LightOutputAdjustmentError.invalidLight }',
    'maximum_candela_is_100000': 'maximum.candela = 100_000',
    'maximum_forward_model_is_valid_finite_positive_and_request_bounded':
        'guard maximum.isValid,\n              let maximumLux = StudioPhotometry.illuminance(for: maximum, in: scene),\n              maximumLux.isFinite, maximumLux > 0, targetLux <= maximumLux else',
    'quotient_must_be_positive_and_valid_or_use_valid_maximum':
        'if adjusted.candela <= 0 || !adjusted.isValid',
    'forward_result_must_be_finite_positive':
        'guard let achievedLux = StudioPhotometry.illuminance(for: adjusted, in: scene),\n              achievedLux.isFinite, achievedLux > 0',
    'forward_ratio_gate_is_1e_minus_9':
        'abs(achievedLux / targetLux - 1) <= 1e-9',
    'already_exact_bypass_requires_positive_source_and_exact_forward_result':
        'if source.candela > 0,\n           StudioPhotometry.illuminance(for: source, in: scene) == targetLux',
}
checks = []
for name, text in requirements.items():
    assert text in solver, name
    checks.append({'name': name, 'path': solver_path,
                   'line': solver[:solver.index(text)].count('\n') + 1, 'pass': True})
model_cap = 'position.isValid && candela.isFinite && (0...100_000).contains(candela)'
assert model_cap in model
checks.append({'name': 'light_model_finite_closed_0_to_100000_cd_range',
               'path': model_path, 'line': model[:model.index(model_cap)].count('\n') + 1,
               'pass': True})
assert solver.index(requirements['validated_source_before_zero_or_positive_solve']) < solver.index('if targetLux == 0')
assert solver.index(requirements['maximum_forward_model_is_valid_finite_positive_and_request_bounded']) < solver.index(requirements['already_exact_bypass_requires_positive_source_and_exact_forward_result'])
assert 'point model; area model' in quality and '<= 1% error' in quality and '<= 5%' in quality
result = {'role': 'W05R01', 'method': 'static source acceptance audit; no runtime probe or package build',
          'worktree_head': head, 'production_baseline': baseline,
          'frozen_probe_module_commit': snapshot, 'files': files,
          'checks': checks, 'validation_order_checks': 2,
          'quality_gates_unchanged': {'point': '1%', 'area': '5%'},
          'limit': 'This role checks the actual source guards and revision identity; independent wave roles supply runtime evidence.'}
(out / 'raw-results.json').write_text(json.dumps(result, indent=2) + '\n')
print(json.dumps(result, indent=2))
