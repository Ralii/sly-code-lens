# sly-code-lens

Code lens for [SLY](https://github.com/joaotavora/sly) showing function and macro reference counts in Common Lisp buffers.

![Example](https://github.com/user-attachments/assets/placeholder.png)

## Overview

sly-code-lens displays inline overlays showing how many times each function or macro is referenced in your codebase. It uses SBCL's `sb-introspect` package to query `who-calls` and `who-macroexpands` data from the running Lisp image.

## Requirements

- Emacs 25.1+
- [SLY](https://github.com/joaotavora/sly)
- SBCL (uses `sb-introspect`)

## Installation

### Emacs 29+ (built-in vc)

```elisp
(use-package sly-code-lens
  :vc (:url "https://github.com/ralii/sly-code-lens"))
```

### straight.el

```elisp
(straight-use-package
 '(sly-code-lens :type git :host github :repo "ralii/sly-code-lens"))
```

### Doom Emacs

Add to `packages.el`:

```elisp
(package! sly-code-lens
  :recipe (:host github :repo "ralii/sly-code-lens"))
```

Then run `doom sync`.

### Manual

Clone the repository and add to your load path:

```elisp
(add-to-list 'load-path "/path/to/sly-code-lens")
(require 'sly-code-lens)
```

## Usage

### Commands

| Command | Description |
|---------|-------------|
| `M-x sly-code-lens-refresh` | Add reference counts to all `defun`/`defmacro` in buffer |
| `M-x sly-code-lens-show-uses-at-point` | Show reference count for symbol at point |
| `M-x sly-code-lens-remove-overlays` | Remove all code lens overlays |

### Automatic Refresh

The package automatically refreshes overlays when opening Lisp files with an active SLY connection.

### Example Output

After running `sly-code-lens-refresh`, you'll see overlays like:

```lisp
(defun calculate-total (items)           3 references
  ...)

(defmacro with-retry (n &body body)      1 reference
  ...)
```

## Customization

### Face

Customize the appearance of the overlay text:

```elisp
(set-face-attribute 'sly-code-lens-face nil
                    :foreground "gray50"
                    :height 0.85)
```

## License

GPL-3.0
