import win32print
import socket
from utils.ticket import generate_ticket_text
from PIL import ImageWin
import io
import win32ui


def print_ticket(printer_name, content, qr_img=None):
    hPrinter = win32print.OpenPrinter(printer_name)
    hDC = win32ui.CreateDC()
    hDC.CreatePrinterDC(printer_name)
    hDC.StartDoc("Factura")
    hDC.StartPage()

    font = win32ui.CreateFont({
        "name": "Courier New",
        "height": 24,  # tamaño legible
        "weight": 700
    })

    hDC.SelectObject(font)

    y = 10
    left_margin = 0
    paper_width = 384

    for line in content.split("\n"):
        if not line.strip():
            y += 12
            continue

        while len(line) > 42:
            part = line[:42]
            hDC.TextOut(left_margin, y, part)
            line = line[42:]
            y += 24

        if any(line.strip().startswith(k) for k in ["Factura"]):
            text_width, _ = hDC.GetTextExtent(line)
            x = (paper_width - text_width) // 2
        else:
            x = left_margin

        hDC.TextOut(x, y, line)
        y += 26

    if qr_img:
        qr_size = 300
        qr_img = qr_img.resize((qr_size, qr_size))
        x_centered = (paper_width - qr_size) // 2
        dib = ImageWin.Dib(qr_img)
        dib.draw(hDC.GetHandleOutput(), (x_centered, y + 10, x_centered + qr_size, y + 10 + qr_size))
        y += qr_size + 20

    hDC.EndPage()
    hDC.EndDoc()
    hDC.DeleteDC()
    win32print.ClosePrinter(hPrinter)

    print("[🖨️] Ticket impreso correctamente.")

def print_invoice(data, destination):
    content, qr_image = generate_ticket_text(data)
    if destination.replace(".", "").isdigit():
        with socket.socket() as s:
            s.connect((destination, 9100))
            s.sendall(content.encode("utf-8"))
        print(f"[🖨️] Ticket enviado por red a {destination}")
    else:
        print_ticket(destination, content, qr_image)
