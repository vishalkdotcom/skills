# Validate — ship-django

From `wovo/`:

```bash
uv run pre-commit run --files <paths-you-changed>
uv run manage.py test <narrow_scope>
uv run manage.py test <parent_module>
```

- **Narrow** during implement: class or module covering changed behaviour.
- **Parent module** once at Validate end when behaviour changed — e.g. if you touched `CategoryColumnMeanTests`, also run `survey.tests.test_survey_table_excel_export`.
