"""Terminal occurrences are a projection of the normalized tree, never a parser."""
from taxonomy import S, K
from build_taxonomy import occurrences
from build_decompositions import build as build_trees, extract as extract_tree
from build_seed import KVG_COMMIT


def extract(root, radical_forms, rules):
    return occurrences(extract_tree(root, radical_forms, {}, rules))


def build():
    rows, characters = [], {}
    for row in build_trees():
        leaves = occurrences(row['tree'])
        for leaf in leaves:
            leaf.update(kanji_id=row['kanji_id'], component_version=3, kanjivg_commit=KVG_COMMIT)
        characters[chr(row['kanji_id'])] = leaves
        rows.extend(leaves)
    return rows, characters


if __name__ == '__main__':
    from build_taxonomy import main
    main()
