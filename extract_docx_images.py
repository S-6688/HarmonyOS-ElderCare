"""Extract and map images from the Word doc to their page labels."""
import sys, os, zipfile, re, shutil
from PIL import Image

sys.stdout.reconfigure(encoding='utf-8')

DOCX = r'C:\Users\15053\Desktop\银龄通智慧养老服务平台项目开发文档.docx'
MEDIA_DIR = r'D:\HarmonyOS_ElderCare\docs_assets\docx_images\word\media'
OUT_DIR = r'D:\HarmonyOS_ElderCare\docs_assets\docx_extracted'
os.makedirs(OUT_DIR, exist_ok=True)

# 1. Build rId -> image file mapping from relationships
z = zipfile.ZipFile(DOCX, 'r')
rels_xml = z.read('word/_rels/document.xml.rels').decode('utf-8')

rid_map = {}
pattern1 = re.compile(r'Id="(rId\d+)"[^>]*Target="(media/image\d+\.png)"')
for m in pattern1.finditer(rels_xml):
    rid_map[m.group(1)] = m.group(2)
print("rId -> file mapping:")
for k, v in sorted(rid_map.items(), key=lambda x: int(re.search(r'\d+', x[0]).group())):
    print(f"  {k} -> {v}")

# 2. Parse document.xml to find images in order with context
doc_xml = z.read('word/document.xml').decode('utf-8')

# Find image references and their surrounding paragraph text
# Split into paragraphs
paras = doc_xml.split('</w:p>')
img_sequence = []
for para in paras:
    blip_matches = list(re.finditer(r'r:embed="(rId\d+)"', para))
    if blip_matches:
        # Get text content of this paragraph
        text = re.sub(r'<[^>]+>', '', para).strip()
        for bm in blip_matches:
            rid = bm.group(1)
            img_file = rid_map.get(rid, 'unknown')
            img_sequence.append((rid, img_file, text[:120]))

print("\nImage sequence in document:")
for i, (rid, img_file, text) in enumerate(img_sequence):
    print(f"  [{i}] {rid} -> {img_file} | context: {text}")

# 3. Copy images with descriptive names based on document context
# Based on the document structure (P66-P104), images appear after headings:
# image1 (rId7) -> after P66 "启动页" -> SplashPage
# image2 (rId8) -> after P70 "引导页" -> GuidePage
# etc.

# Map based on known document structure
name_map = {
    'image1.png': 'docx_splash.png',
    'image2.png': 'docx_guide.png',
    'image3.png': 'docx_login.png',
    'image4.png': 'docx_home.png',
    'image5.png': 'docx_health.png',
    'image6.png': 'docx_knowledge.png',
    'image7.png': 'docx_knowledge_detail.png',
    'image8.png': 'docx_contacts.png',
    'image9.png': 'docx_medication.png',
    'image10.png': 'docx_settings.png',
}

print("\nCopying and renaming images:")
for src_name, dst_name in name_map.items():
    src = os.path.join(MEDIA_DIR, src_name)
    dst = os.path.join(OUT_DIR, dst_name)
    if os.path.exists(src):
        img = Image.open(src)
        print(f"  {src_name} -> {dst_name} ({img.size[0]}x{img.size[1]})")
        shutil.copy2(src, dst)
    else:
        print(f"  {src_name} NOT FOUND")

z.close()
print("\nDone! Images saved to:", OUT_DIR)
