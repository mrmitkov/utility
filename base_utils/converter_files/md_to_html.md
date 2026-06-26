
# Convertire Markdown in HTML

Per generare un file HTML a partire da un documento Markdown, è possibile usare il modulo Python `markdown`.

## Prerequisiti

- Python installato
- Pacchetto `markdown` installato:

```bash
pip install markdown
```

## Esempio

```bash
python -c "import markdown; print(markdown.markdown(open('runbook.md').read()))" > runbook.html
```

## Uso di un template

Sì, è possibile usare un template HTML per aggiungere stile e struttura al risultato. In questo caso puoi:

1. preparare un file HTML base con segnaposto come `{{ content }}`;
2. convertire il Markdown in HTML;
3. inserire il contenuto generato nel template.

Esempio concettuale:

```html
<!DOCTYPE html>
<html>
<head>
  <title>Documento</title>
</head>
<body>
  {{ content }}
</body>
</html>
```

## Nota

- Sostituisci `runbook.md` con il nome del tuo file Markdown.
- Il risultato verrà salvato nel file `runbook.html`.