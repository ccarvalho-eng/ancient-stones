%Doctor.Config{
  ignore_modules: [],
  ignore_paths: [~r/^test\/support\//],
  min_module_doc_coverage: 0,
  min_module_spec_coverage: 0,
  min_overall_doc_coverage: 10,
  min_overall_moduledoc_coverage: 12,
  min_overall_spec_coverage: 0,
  exception_moduledoc_required: true,
  raise: true,
  reporter: Doctor.Reporters.Summary,
  struct_type_spec_required: false,
  umbrella: false
}
