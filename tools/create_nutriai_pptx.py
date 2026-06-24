from __future__ import annotations

import html
import re
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "NutriAI_Class_Presentation.md"
OUTPUT = ROOT / "NutriAI_Class_Presentation.pptx"


def clean_line(line: str) -> str:
    line = line.strip()
    line = re.sub(r"^#+\s*", "", line)
    line = re.sub(r"^[-*]\s*", "", line)
    line = line.replace("`", "")
    line = re.sub(r"\*\*(.*?)\*\*", r"\1", line)
    line = re.sub(r"_(.*?)_", r"\1", line)
    return line.strip()


def parse_deck(markdown: str) -> list[dict[str, object]]:
    sections = [part.strip() for part in re.split(r"\n---\n", markdown) if part.strip()]
    slides: list[dict[str, object]] = []

    for raw in sections:
        content = raw.split("Speaker notes:", 1)[0]
        lines = [line.rstrip() for line in content.splitlines()]
        lines = [line for line in lines if line.strip()]

        title = ""
        body: list[str] = []
        in_code = False

        for line in lines:
            stripped = line.strip()
            if stripped.startswith("```"):
                in_code = not in_code
                continue
            if not title and stripped.startswith("#"):
                title = clean_line(stripped)
                continue
            if stripped.lower().startswith("class presentation"):
                continue
            if stripped.lower().startswith("presented by:"):
                body.append(clean_line(stripped))
                continue
            if stripped.lower().startswith("course:") or stripped.lower().startswith("date:"):
                body.append(clean_line(stripped))
                continue
            if stripped.startswith("#"):
                if not title:
                    title = clean_line(stripped)
                else:
                    body.append(clean_line(stripped))
                continue
            if stripped.startswith("|") or set(stripped) <= {"|", "-", " "}:
                continue
            if in_code:
                if stripped not in {"↓", "+"}:
                    body.append(clean_line(stripped))
                else:
                    body.append(stripped)
                continue
            if stripped:
                cleaned = clean_line(stripped)
                if cleaned:
                    body.append(cleaned)

        if title:
            slides.append({"title": title, "body": body[:9]})

    return slides


def text_body_xml(lines: list[str], start_y: int = 1_650_000) -> str:
    paras = []
    for i, line in enumerate(lines):
        safe = html.escape(line)
        bullet = "" if i == 0 and not line.startswith(("To ", "Many ", "Example:", "The ")) else '<a:buChar char="•"/>'
        paras.append(
            f"""
            <a:p>
              <a:pPr marL="220000" indent="-160000">{bullet}</a:pPr>
              <a:r>
                <a:rPr lang="en-US" sz="2350"/>
                <a:t>{safe}</a:t>
              </a:r>
            </a:p>"""
        )
    return "\n".join(paras)


def slide_xml(title: str, body: list[str], slide_number: int) -> str:
    title_safe = html.escape(title)
    body_xml = text_body_xml([str(line) for line in body])
    return f"""<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
       xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
       xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
  <p:cSld>
    <p:bg>
      <p:bgPr>
        <a:solidFill><a:srgbClr val="F7FBF8"/></a:solidFill>
        <a:effectLst/>
      </p:bgPr>
    </p:bg>
    <p:spTree>
      <p:nvGrpSpPr>
        <p:cNvPr id="1" name=""/>
        <p:cNvGrpSpPr/>
        <p:nvPr/>
      </p:nvGrpSpPr>
      <p:grpSpPr>
        <a:xfrm>
          <a:off x="0" y="0"/>
          <a:ext cx="0" cy="0"/>
          <a:chOff x="0" y="0"/>
          <a:chExt cx="0" cy="0"/>
        </a:xfrm>
      </p:grpSpPr>
      <p:sp>
        <p:nvSpPr>
          <p:cNvPr id="2" name="Title"/>
          <p:cNvSpPr txBox="1"/>
          <p:nvPr/>
        </p:nvSpPr>
        <p:spPr>
          <a:xfrm><a:off x="540000" y="420000"/><a:ext cx="8050000" cy="760000"/></a:xfrm>
          <a:prstGeom prst="rect"><a:avLst/></a:prstGeom>
          <a:noFill/>
        </p:spPr>
        <p:txBody>
          <a:bodyPr wrap="square"/>
          <a:lstStyle/>
          <a:p>
            <a:r>
              <a:rPr lang="en-US" sz="3900" b="1">
                <a:solidFill><a:srgbClr val="0F172A"/></a:solidFill>
              </a:rPr>
              <a:t>{title_safe}</a:t>
            </a:r>
          </a:p>
        </p:txBody>
      </p:sp>
      <p:sp>
        <p:nvSpPr>
          <p:cNvPr id="3" name="Body"/>
          <p:cNvSpPr txBox="1"/>
          <p:nvPr/>
        </p:nvSpPr>
        <p:spPr>
          <a:xfrm><a:off x="760000" y="1420000"/><a:ext cx="7900000" cy="4600000"/></a:xfrm>
          <a:prstGeom prst="roundRect"><a:avLst/></a:prstGeom>
          <a:solidFill><a:srgbClr val="FFFFFF"/></a:solidFill>
          <a:ln w="16000"><a:solidFill><a:srgbClr val="CDEBDD"/></a:solidFill></a:ln>
        </p:spPr>
        <p:txBody>
          <a:bodyPr wrap="square" lIns="260000" tIns="220000" rIns="260000" bIns="220000"/>
          <a:lstStyle/>
          {body_xml}
        </p:txBody>
      </p:sp>
      <p:sp>
        <p:nvSpPr>
          <p:cNvPr id="4" name="Footer"/>
          <p:cNvSpPr txBox="1"/>
          <p:nvPr/>
        </p:nvSpPr>
        <p:spPr>
          <a:xfrm><a:off x="650000" y="6400000"/><a:ext cx="7900000" cy="300000"/></a:xfrm>
          <a:prstGeom prst="rect"><a:avLst/></a:prstGeom>
          <a:noFill/>
        </p:spPr>
        <p:txBody>
          <a:bodyPr/>
          <a:lstStyle/>
          <a:p>
            <a:r>
              <a:rPr lang="en-US" sz="1200">
                <a:solidFill><a:srgbClr val="10B981"/></a:solidFill>
              </a:rPr>
              <a:t>NutriAI • AI Nutrition and Meal Planner • {slide_number}</a:t>
            </a:r>
          </a:p>
        </p:txBody>
      </p:sp>
    </p:spTree>
  </p:cSld>
  <p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr>
</p:sld>"""


def write_pptx(slides: list[dict[str, object]]) -> None:
    slide_overrides = "\n".join(
        f'<Override PartName="/ppt/slides/slide{i}.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>'
        for i in range(1, len(slides) + 1)
    )
    slide_rels = "\n".join(
        f'<Relationship Id="rId{i}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide{i}.xml"/>'
        for i in range(1, len(slides) + 1)
    )
    slide_ids = "\n".join(
        f'<p:sldId id="{255 + i}" r:id="rId{i}"/>'
        for i in range(1, len(slides) + 1)
    )

    with zipfile.ZipFile(OUTPUT, "w", zipfile.ZIP_DEFLATED) as zf:
        zf.writestr(
            "[Content_Types].xml",
            f"""<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/ppt/presentation.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml"/>
  <Override PartName="/ppt/theme/theme1.xml" ContentType="application/vnd.openxmlformats-officedocument.theme+xml"/>
  {slide_overrides}
</Types>""",
        )
        zf.writestr(
            "_rels/.rels",
            """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="ppt/presentation.xml"/>
</Relationships>""",
        )
        zf.writestr(
            "ppt/presentation.xml",
            f"""<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:presentation xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
                xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
                xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
  <p:sldIdLst>
    {slide_ids}
  </p:sldIdLst>
  <p:sldSz cx="9144000" cy="6858000" type="screen4x3"/>
  <p:notesSz cx="6858000" cy="9144000"/>
</p:presentation>""",
        )
        zf.writestr(
            "ppt/_rels/presentation.xml.rels",
            f"""<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  {slide_rels}
  <Relationship Id="rId{len(slides) + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" Target="theme/theme1.xml"/>
</Relationships>""",
        )
        zf.writestr(
            "ppt/theme/theme1.xml",
            """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<a:theme xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" name="NutriAI Theme">
  <a:themeElements>
    <a:clrScheme name="NutriAI">
      <a:dk1><a:srgbClr val="0F172A"/></a:dk1>
      <a:lt1><a:srgbClr val="FFFFFF"/></a:lt1>
      <a:dk2><a:srgbClr val="065F46"/></a:dk2>
      <a:lt2><a:srgbClr val="ECFDF5"/></a:lt2>
      <a:accent1><a:srgbClr val="10B981"/></a:accent1>
      <a:accent2><a:srgbClr val="3B82F6"/></a:accent2>
      <a:accent3><a:srgbClr val="F59E0B"/></a:accent3>
      <a:accent4><a:srgbClr val="EF4444"/></a:accent4>
      <a:accent5><a:srgbClr val="8B5CF6"/></a:accent5>
      <a:accent6><a:srgbClr val="14B8A6"/></a:accent6>
      <a:hlink><a:srgbClr val="2563EB"/></a:hlink>
      <a:folHlink><a:srgbClr val="7C3AED"/></a:folHlink>
    </a:clrScheme>
    <a:fontScheme name="NutriAI Fonts">
      <a:majorFont><a:latin typeface="Aptos Display"/></a:majorFont>
      <a:minorFont><a:latin typeface="Aptos"/></a:minorFont>
    </a:fontScheme>
    <a:fmtScheme name="NutriAI Format">
      <a:fillStyleLst><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:fillStyleLst>
      <a:lnStyleLst><a:ln w="9525"><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:ln></a:lnStyleLst>
      <a:effectStyleLst><a:effectStyle><a:effectLst/></a:effectStyle></a:effectStyleLst>
      <a:bgFillStyleLst><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:bgFillStyleLst>
    </a:fmtScheme>
  </a:themeElements>
</a:theme>""",
        )
        for i, slide in enumerate(slides, start=1):
            zf.writestr(
                f"ppt/slides/slide{i}.xml",
                slide_xml(str(slide["title"]), list(slide["body"]), i),
            )


def main() -> None:
    markdown = SOURCE.read_text(encoding="utf-8")
    slides = parse_deck(markdown)
    write_pptx(slides)
    print(f"Created {OUTPUT}")
    print(f"Slides: {len(slides)}")


if __name__ == "__main__":
    main()
