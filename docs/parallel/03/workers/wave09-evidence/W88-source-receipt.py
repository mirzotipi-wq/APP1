#!/usr/bin/env python3
"""Bounded source-identity receipt only; executes no Swift/UI/test workload."""
from pathlib import Path
import hashlib
import json
import platform
import subprocess

BASE = Path('/tmp/keyfill03-7f4b/workers/W88-accessibility-privacy')
CANDIDATE = Path('/tmp/keyfill03-7f4b/workers/W84-implementation')
OUT = Path(__file__).resolve().parent

def git(*args):
    return subprocess.check_output(['git', '-C', str(BASE), *args], text=True).strip()

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

paths = [
    'App/ReferenceStudyPreview.swift',
    'Sources/LightingCore/ReferencePNG.swift',
    'App/ReferencePhoto.swift',
    'App/ReferenceComparisonView.swift',
    'App/StudioView.swift',
    'NativeTests/StudyPreviewPipelineTests.swift',
    'NativeTests/ReferencePhotoTests.swift',
    'Tests/LightingCoreTests/ReferencePNGTests.swift',
]
sources = []
for path in paths:
    baseline = digest(BASE / path)
    candidate = digest(CANDIDATE / path)
    sources.append({'path': path, 'baseline_sha256': baseline,
                    'candidate_sha256': candidate, 'byte_identical': baseline == candidate})

expected = {
    'App/ReferenceStudyPreview.swift': 'e04832818b9b7619799ba1cab4db279e51cf0e93e7be201ac3cd2fb367a8f338',
    'NativeTests/StudyPreviewAdoptionTests.swift': 'abd3fa97bb0cda6d45e4e9f66b068f1155ea4672b87542a081c33e6d72967f91',
}
candidate_identity = {path: {'sha256': digest(CANDIDATE / path),
                            'expected_sha256': value,
                            'matches_assignment': digest(CANDIDATE / path) == value}
                      for path, value in expected.items()}

receipt = {
    'runtime_id': '/root/wave09/w88_accessibility_privacy',
    'parent': '/root/wave09',
    'role': 'accessibility/privacy independent source review',
    'baseline_commit': git('rev-parse', 'HEAD'),
    'baseline_tree': git('rev-parse', 'HEAD^{tree}'),
    'private_worktree': str(BASE),
    'private_status': git('status', '--short'),
    'host': platform.platform(),
    'candidate_identity': candidate_identity,
    'source_identity': sources,
    'patch_sha256': digest(OUT / 'W84-preview-adoption.patch'),
    'receipt_script_sha256': digest(Path(__file__)),
    'commands': [
        {'cwd': str(BASE), 'command': 'git rev-parse HEAD && git status --short'},
        {'cwd': str(CANDIDATE), 'command': 'sha256sum App/ReferenceStudyPreview.swift NativeTests/StudyPreviewAdoptionTests.swift'},
        {'cwd': str(BASE), 'command': 'nl -ba Sources/LightingCore/ReferencePNG.swift && nl -ba App/ReferencePhoto.swift'},
        {'cwd': str(CANDIDATE), 'command': "sed -n '119,285p' App/ReferenceStudyPreview.swift && cat NativeTests/StudyPreviewAdoptionTests.swift"},
        {'cwd': str(OUT.parent.parent.parent.parent.parent), 'command': f'git diff --no-index {BASE}/App/ReferenceStudyPreview.swift {CANDIDATE}/App/ReferenceStudyPreview.swift', 'exit': 1, 'meaning': 'expected: candidate differs'},
        {'cwd': str(BASE), 'command': f'python3 {Path(__file__).resolve()}'},
    ],
    'source_findings': [
        {'id': 'W88-AX-01', 'location': 'candidate App/ReferenceStudyPreview.swift:125-175,212-234',
         'assessment': 'No source-level reintroduction of W78 warning gap found.',
         'evidence': 'A retained same-subject image with a positive unsupported count supplies the count both to its explicit previous-render image label and visible status Text. Active ticket invalidation makes retained equal-scene pixels previous during pause, disappearance and revalidation; no current backend badge or current lighting advice is emitted until adoption.',
         'limit': 'SwiftUI task scheduling, accessibility grouping, audibility and screen layout are not established by source inspection.'},
        {'id': 'W88-AX-02', 'location': 'candidate NativeTests/StudyPreviewAdoptionTests.swift:14-21,106-137,166-244',
         'assessment': 'Hosted regression is meaningful source coverage, not an executed result.',
         'evidence': 'One mounted view, controlled A/B/A producer handshakes, positive previous/updating and count assertions, negative stale backend/current warning assertions, then CPU adoption. Scene phase is fixed active. Node traversal records identifiers and labels without proving VoiceOver focusability.',
         'limit': 'Paused/reattachment scenarios, actual backend downgrade, largest Dynamic Type, contrast, hit area and VoiceOver remain unverified.'},
        {'id': 'W88-AX-03', 'location': 'candidate App/ReferenceStudyPreview.swift:106-107,155-201; baseline App/ReferenceComparisonView.swift:261-262; App/StudioView.swift:504-522',
         'assessment': 'Text-based state cues and retry action remain; no layout pass claimed.',
         'evidence': 'Paused/updating/rendering/unavailable have distinct text. Retry label has minHeight 44 inside ScrollView. Fixed 200/280-point consumer heights and caption warnings need observed large-text checking. Status accessibilityValue still says Showing the previous scene during same-scene revalidation: a wording imprecision, not proof that another scene is displayed.'},
        {'id': 'W88-PRIV-01', 'location': 'candidate App/ReferenceStudyPreview.swift:106-107,130-139; unchanged App/ReferenceComparisonView.swift:156-177; App/ReferencePhoto.swift:55-111; Sources/LightingCore/ReferencePNG.swift:10-49',
         'assessment': 'No new privacy boundary or metadata behavior introduced by candidate.',
         'evidence': 'Study labels contain fixed synthetic-subject descriptions, status and pixel count; no asset identifiers, paths or photo-derived identity. Imported-photo label is generic, marked privacySensitive and photo hidden while inactive. Sanitizer redraws bounded pixels into fresh sRGB, encodes with nil properties, then retains only structural/color/transparency PNG chunks. Text/EXIF chunks are excluded; original CRCs retained, validation delegated to ImageIO.',
         'limit': 'ReferencePNG is a filter for freshly encoded derivatives, not arbitrary-source sanitization proof. No import/permissions/network runtime testing performed.'},
    ],
    'manual_state_review': [
        'Current positive-count frame: current warning; backend allowed.',
        'Active retained positive-count frame: previous-qualified count in image label and Text; updating state; no backend.',
        'Inactive retained positive-count frame after task invalidation: same count; paused state; no backend.',
        'Reattachment after onDisappear: previous until fresh ticket publication; count remains tied to retained frame.',
        'Zero-count retained frame: previous state without unsupported warning.',
        'Different subject: retained image excluded.',
        'Nil-image current failure: unavailable/retry; activation clears equal-request nil frame before retry.',
    ],
    'inspection_limits': [
        'No production changes, children, build, typecheck, suite, render or benchmark executed by W88.',
        'Root native execution pending; source/identifier presence is not UI/layout/VoiceOver acceptance.',
        'Original twelve raw masks unavailable; final all-zero masks cannot establish original-mask equality. No mask comparison claimed here.',
        'Existing historical failures/evidence preserved. No milestone or release promotion.',
        'Qualitative approximately 60 percent review checkpoint used; exact token counters unavailable.',
        'Initial broad text search was truncated and not used as exhaustive evidence. W84 new receipt was absent from immutable baseline; subsequently read from integration checkout.',
    ],
    'tests_run': [],
    'status': 'completed bounded source review; native presentation risk remains unverified',
}
output = OUT / 'W88-accessibility-privacy.json'
output.write_text(json.dumps(receipt, indent=2) + '\n')
print(json.dumps({'receipt': str(output), 'sha256': digest(output),
                  'baseline': receipt['baseline_commit'],
                  'candidate_hashes_match': all(v['matches_assignment'] for v in candidate_identity.values()),
                  'unchanged_reviewed_paths': sum(item['byte_identical'] for item in sources),
                  'reviewed_paths': len(sources), 'private_status': receipt['private_status']}, indent=2))
