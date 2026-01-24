import re
import pdfplumber
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas
from reportlab.lib.units import mm
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfbase import pdfmetrics
from reportlab.lib.utils import ImageReader
from PIL import Image
from typing import TypedDict


# Eingabe / Ausgabe
INPUT_PDFS = [
    #"assets/data/11_AK0_DFM2025.pdf",
    "assets/data/11_AK0_AK2_DFM2025.pdf",
    "assets/data/12_AK1_DFM2025.pdf",
    #"assets/data/13_AK2_DFM2025.pdf",
    "assets/data/14_AK3_AlleLV_DFM2025.pdf"
]
OUTPUT_PDF = "DFM_2025_Titelkärtchen.pdf"

class Record(TypedDict):
    nachname: str
    vorname: str
    titel: str
    wertung: str

records: list[Record] = []
record_count = 0
for input_pdf in INPUT_PDFS:
    with pdfplumber.open(input_pdf) as pdf:
        ak_tag = None
        for page in pdf.pages:
            text = page.extract_text()
            if not text:
                continue

            if "Altersklasse 1" in text:
                ak_tag = "AK1"
            elif "Altersklasse 2" in text:
                ak_tag = "AK2"

            for line in text.split("\n"):
                if "Urkunde" in line or "Medaille" in line:
                    m = re.search(
                        r"^([^,]+),\s*(Dr\.)?\s*([^\s]+)(?:\s+((?:\S*(?:FIAP|DVF)\S*\s*)+))?\s+(.*?)\s+»(.*?)«\s+(Urkunde|Medaille)",
                        line
                    )
                    if m:
                        nachname = m.group(1).strip()
                        doktor = m.group(2) or ""
                        vorname = m.group(3).strip()
                        ehrentitel = m.group(4).strip() if m.group(4) else ""
                        club = m.group(5).strip()
                        bildtitel = m.group(6).strip()
                        wertung = m.group(7).strip()

                        # Altersklassen-Logik
                        if record_count < 3:
                            current_ak_tag = "AK0"
                        else:
                            current_ak_tag = ak_tag

                        # Namen zusammenbauen
                        if current_ak_tag:
                            nachname += f" {current_ak_tag}"
                        if ehrentitel:
                            nachname += " " + ehrentitel  # FIAP/DVF an den Namen hängen

                        records.append({
                            "nachname": nachname,
                            "vorname": (doktor + " " if doktor else "") + vorname,
                            "titel": bildtitel,
                            "wertung": wertung
                        })
                        record_count += 1
records.append({
    "nachname": "DeLaan",
    "vorname": "Corry",
    "titel": "Mothership-Cloud - Rotierende Superzelle",
    "wertung": "Urkunde"
})
records.append({
    "nachname": "Winkler",
    "vorname": "Regina",
    "titel": "Pelikane in der aufgehenden Sonne",
    "wertung": "Urkunde"
})
records.append({
    "nachname": "Scherhag MDVF",
    "vorname": "Ute",
    "titel": "Rostig",
    "wertung": "Jurorbild"
})
records.append({
    "nachname": "Seller",
    "vorname": "Andreas",
    "titel": "Papageitaucher",
    "wertung": "Jurorbild"
})
records.append({
    "nachname": "Wächter",
    "vorname": "Gertrud",
    "titel": "Ausfahrt",
    "wertung": "Jurorbild"
})
records.append({
    "nachname": "Köppert",
    "vorname": "Martin",
    "titel": "Hidding",
    "wertung": "Jurorbild"
})
records.append({
    "nachname": "Prager",
    "vorname": "Luisa",
    "titel": "Selbstportrait",
    "wertung": "Urkunde"
})
records.append({
    "nachname": "Eisenreich",
    "vorname": "Werner",
    "titel": "Westerhold",
    "wertung": "Medaille"
})


print(f"{len(records)} Kärtchen gefunden.")

# PDF erzeugen
c = canvas.Canvas(OUTPUT_PDF, pagesize=A4)
page_width, page_height = A4

# Kartengröße
card_width = 21 / 2 * 10 * mm   # 10 cm
#card_height = 29.7 / 8 * 10 * mm   # 3,5 cm
card_height = 40 * mm

cards_per_row = 2
cards_per_col = 7
cards_per_page = cards_per_row * cards_per_col

margin_right = 3 * mm  # Reduced left margin
margin_left = margin_right * 3  # Make the right margin equal to the left margin

# Schriftart registrieren
pdfmetrics.registerFont(TTFont('OpenSans', 'assets/font/OpenSans-Regular.ttf'))
pdfmetrics.registerFont(TTFont('OpenSans-Bold', 'assets/font/OpenSans-Bold.ttf'))
pdfmetrics.registerFont(TTFont('OpenSans-SemiBold', 'assets/font/OpenSans-SemiBold.ttf'))


# PNG Image (top center)
original_image = Image.open('assets/img/DVF_Logo_80_schwarz_mit_Schrift_3000x621-1-scaled.png').convert("RGBA")

# Create a white background image
background = Image.new("RGBA", original_image.size, (255, 255, 255, 255))

# Blend the original image with the white background
blended_image = Image.alpha_composite(background, original_image)

# Save the blended image as a temporary file
blended_image_path = "assets/img/temp_blended_image.png"
blended_image.save(blended_image_path, "PNG")
image_width = 30 * mm  # Set a fixed width for the image
image_height = image_width * (blended_image.height / blended_image.width)

# Inside the loop for each card
for i, rec in enumerate(records):
    col = i % cards_per_row
    row = (i // cards_per_row) % cards_per_col

    if i > 0 and i % cards_per_page == 0:
        c.showPage()

    x0 = col * card_width
    y0 = page_height - (row + 1) * card_height

    # Draw the transparent image (top-right)
    image_x = x0 + card_width - image_width - 10 * mm  # Align to the right with a margin
    image_y = y0 + card_height - image_height - 5 * mm  # Small margin from the top
    c.drawImage(ImageReader(blended_image_path), image_x, image_y, width=image_width, height=image_height)

    # Title (moved further down and made larger)
    title_text = rec['titel']
    title_font_size = 18 if len(title_text) <= 28 else 17 if len(title_text) <= 30 else 15 if len(title_text) <= 35 else 12.5  # Reduce size by 1 if longer than 28 characters
    #font_type = "OpenSans-SemiBold" if len(title_text) <= 35 else "OpenSans-Bold"
    c.setFont("OpenSans-SemiBold", title_font_size)
    c.drawString(x0 + margin_left, y0 + card_height - 20 * mm, title_text)

    # Name (adjusted for new margins)
    c.setFont("OpenSans", 12)
    name_text = f"{rec['vorname']} {rec['nachname']}"
    c.drawString(x0 + margin_left, y0 + 8 * mm, name_text)

    # Award (adjusted for new margins)
    c.setFont("OpenSans", 14)
    award_text = rec['wertung']
    award_text_width = c.stringWidth(award_text, "OpenSans", 14)
    c.drawString(x0 + card_width - award_text_width - margin_right * 2, y0 + 8 * mm, award_text)

    # --- Trennlinien nur einmal pro Seite zeichnen ---
    if (i % cards_per_page) == 0:
        for r in range(1, cards_per_col):
            y_line = page_height - r * card_height
            c.line(0, y_line, page_width, y_line)

c.save()
print(f"PDF gespeichert: {OUTPUT_PDF}")