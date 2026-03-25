// src/resolver/resolver_test.odin
package resolver

import "core:testing"
import "core:os"
import "core:strings"
import "../parser"

// ─── component + import validation ────────────────────────────────────────────

@(test)
test_resolve_valid_component :: proc(t: ^testing.T) {
    registry := make_registry()
    register_component(&registry, "components/card", "Card")

    src := `<script lang="odin">
import "components/card"
</script>
<card.Card title="Hello"></card.Card>`

    doc, _ := parser.parse(src, "test.ohtml")
    errs := resolve(&doc, registry)
    testing.expect_value(t, len(errs), 0)
}

@(test)
test_resolve_unknown_component :: proc(t: ^testing.T) {
    registry := make_registry()
    // registry has no "components/card" package registered

    src := `<script lang="odin">
import "components/card"
</script>
<card.Card title="Hello"></card.Card>`

    doc, _ := parser.parse(src, "test.ohtml")
    errs := resolve(&doc, registry)
    testing.expect(t, len(errs) > 0, "should report unknown component")
}

@(test)
test_resolve_missing_import :: proc(t: ^testing.T) {
    registry := make_registry()
    register_component(&registry, "components/card", "Card")

    // No import declared but component used
    src := `<card.Card title="Hello"></card.Card>`

    doc, _ := parser.parse(src, "test.ohtml")
    errs := resolve(&doc, registry)
    testing.expect(t, len(errs) > 0, "should report missing import")
}

@(test)
test_resolve_aliased_import :: proc(t: ^testing.T) {
    registry := make_registry()
    register_component(&registry, "components/ui/button", "Button")

    src := `<script lang="odin">
import btn "components/ui/button"
</script>
<btn.Button label="Click"></btn.Button>`

    doc, _ := parser.parse(src, "test.ohtml")
    errs := resolve(&doc, registry)
    testing.expect_value(t, len(errs), 0)
}

@(test)
test_resolve_wrong_component_name :: proc(t: ^testing.T) {
    registry := make_registry()
    register_component(&registry, "components/card", "Card")
    // Note: "Cardz" is not registered

    src := `<script lang="odin">
import "components/card"
</script>
<card.Cardz title="Hello"></card.Cardz>`

    doc, _ := parser.parse(src, "test.ohtml")
    errs := resolve(&doc, registry)
    testing.expect(t, len(errs) > 0, "should report wrong component name")
}

// ─── layout chain ─────────────────────────────────────────────────────────────

write_file :: proc(path: string, content: string) {
    _ = os.write_entire_file(path, content)
}

mkdir_all :: proc(path: string) {
    _ = os.mkdir_all(path)
}

@(test)
test_resolve_layout_chain :: proc(t: ^testing.T) {
    // Create temp directory structure:
    // /tmp/odin_test_views_chain/+layout.ohtml
    // /tmp/odin_test_views_chain/about/+layout.ohtml
    // /tmp/odin_test_views_chain/about/+page.ohtml
    base := "/tmp/odin_test_views_chain"
    about_dir := strings.concatenate([]string{base, "/about"})
    defer {
        os.remove(strings.concatenate([]string{base, "/+layout.ohtml"}))
        os.remove(strings.concatenate([]string{about_dir, "/+layout.ohtml"}))
        os.remove(strings.concatenate([]string{about_dir, "/+page.ohtml"}))
        os.remove(about_dir)
        os.remove(base)
    }

    mkdir_all(about_dir)
    write_file(strings.concatenate([]string{base, "/+layout.ohtml"}), `<!DOCTYPE html><html><body>{@render children()}</body></html>`)
    write_file(strings.concatenate([]string{about_dir, "/+layout.ohtml"}), `<div class="about-wrapper">{@render children()}</div>`)
    write_file(strings.concatenate([]string{about_dir, "/+page.ohtml"}), `<h1>About Us</h1>`)

    page_path := strings.concatenate([]string{about_dir, "/+page.ohtml"})
    chain := resolve_layout_chain(page_path, base)

    testing.expect_value(t, len(chain), 2)
    if len(chain) == 2 {
        testing.expect(t, strings.has_suffix(chain[0], "/+layout.ohtml") && strings.contains(chain[0], base) && !strings.contains(chain[0], "about"), "first should be root layout")
        testing.expect(t, strings.has_suffix(chain[1], "/+layout.ohtml") && strings.contains(chain[1], "about"), "second should be about layout")
    }
}

@(test)
test_resolve_layout_chain_no_nested :: proc(t: ^testing.T) {
    // views/blog/+page.ohtml — only root layout exists
    base := "/tmp/odin_test_views_no_nested"
    blog_dir := strings.concatenate([]string{base, "/blog"})
    defer {
        os.remove(strings.concatenate([]string{base, "/+layout.ohtml"}))
        os.remove(strings.concatenate([]string{blog_dir, "/+page.ohtml"}))
        os.remove(blog_dir)
        os.remove(base)
    }

    mkdir_all(blog_dir)
    write_file(strings.concatenate([]string{base, "/+layout.ohtml"}), `<!DOCTYPE html><html><body>{@render children()}</body></html>`)
    write_file(strings.concatenate([]string{blog_dir, "/+page.ohtml"}), `<h1>Blog</h1>`)

    page_path := strings.concatenate([]string{blog_dir, "/+page.ohtml"})
    chain := resolve_layout_chain(page_path, base)

    testing.expect_value(t, len(chain), 1)
    if len(chain) >= 1 {
        testing.expect(t, strings.has_suffix(chain[0], "/+layout.ohtml"), "should find root layout")
    }
}

@(test)
test_resolve_layout_chain_no_layouts :: proc(t: ^testing.T) {
    // No layouts at all
    base := "/tmp/odin_test_views_empty"
    page_dir := strings.concatenate([]string{base, "/pages"})
    defer {
        os.remove(strings.concatenate([]string{page_dir, "/+page.ohtml"}))
        os.remove(page_dir)
        os.remove(base)
    }

    mkdir_all(page_dir)
    write_file(strings.concatenate([]string{page_dir, "/+page.ohtml"}), `<h1>Page</h1>`)

    page_path := strings.concatenate([]string{page_dir, "/+page.ohtml"})
    chain := resolve_layout_chain(page_path, base)

    testing.expect_value(t, len(chain), 0)
}
