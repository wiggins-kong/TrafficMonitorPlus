#!/usr/bin/env python3
"""从 changelog.md 中提取指定版本的章节，用于生成 GitHub Release 的说明。

用法:
    extract_changelog.py <changelog 文件路径> <版本号>

版本号可以带或不带 v/V 前缀（例如 V1.86.1 或 1.86.1）。
脚本会找到形如 `## V1.86.1`（标题中包含该版本号）的标题，输出该标题之后、
下一个同级或更高级标题之前的全部内容（不含标题本身）。

退出码:
    0  提取成功
    1  没有找到该版本的章节
    2  参数错误或文件不存在
"""
import re
import sys


def extract(path: str, version: str) -> str:
    with open(path, encoding="utf-8") as f:
        lines = f.read().splitlines()

    heading_re = re.compile(r"^(#{1,6})\s+(.*)$")
    version_re = re.compile(r"(?<![0-9.])[vV]?" + re.escape(version) + r"(?![0-9.])")

    start = None
    level = 0
    end = len(lines)
    for index, line in enumerate(lines):
        matched = heading_re.match(line)
        if not matched:
            continue
        if start is None:
            if version_re.search(matched.group(2)):
                start = index
                level = len(matched.group(1))
        elif len(matched.group(1)) <= level:
            end = index
            break

    if start is None:
        return ""

    body = lines[start + 1:end]
    # 去掉末尾多余的空行与水平分隔线（--- / *** / ___）
    while body and (not body[-1].strip() or re.fullmatch(r"\s*([-*_])\1{2,}\s*", body[-1])):
        body.pop()

    return "\n".join(body)


def main() -> int:
    if len(sys.argv) < 3:
        print(__doc__, file=sys.stderr)
        return 2

    path, raw_version = sys.argv[1], sys.argv[2]
    version = raw_version.lstrip("vV").strip()

    try:
        body = extract(path, version)
    except FileNotFoundError:
        print(f"[extract_changelog] 找不到文件: {path}", file=sys.stderr)
        return 2

    if not body:
        print(f"[extract_changelog] 在 {path} 中没有找到版本 {version} 的章节", file=sys.stderr)
        return 1

    print(body)
    return 0


if __name__ == "__main__":
    sys.exit(main())
