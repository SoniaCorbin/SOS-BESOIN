import jsPDF from 'jspdf'

type InvoicePdfData = {
  invoiceNumber: string
  status: string
  clientName: string
  providerName: string
  requestTitle: string
  requestCategory: string
  createdAt: string
  amount: number
  platformFee: number
  providerAmount: number
}

export function downloadInvoicePdf(data: InvoicePdfData) {
  const doc = new jsPDF({ unit: 'mm', format: 'a4' })
  const marginX = 20
  const pageWidth = doc.internal.pageSize.getWidth()
  let y = 22

  doc.setFont('helvetica', 'bold')
  doc.setFontSize(20)
  doc.text('SOS-BESOIN', marginX, y)
  doc.setFont('helvetica', 'normal')
  doc.setFontSize(10)
  doc.setTextColor(120)
  doc.text("La marketplace d'urgence", marginX, y + 6)

  doc.setFont('helvetica', 'bold')
  doc.setFontSize(14)
  doc.setTextColor(217, 119, 6)
  doc.text('FACTURE', pageWidth - marginX, y, { align: 'right' })
  doc.setFont('helvetica', 'normal')
  doc.setFontSize(10)
  doc.setTextColor(120)
  doc.text(data.invoiceNumber, pageWidth - marginX, y + 6, { align: 'right' })

  y += 14
  doc.setDrawColor(217, 119, 6)
  doc.line(marginX, y, pageWidth - marginX, y)
  y += 10

  const paid = data.status === 'paid'
  doc.setFillColor(paid ? 220 : 255, paid ? 252 : 243, paid ? 231 : 199)
  doc.roundedRect(marginX, y - 5, 28, 8, 1.5, 1.5, 'F')
  doc.setTextColor(paid ? 21 : 146, paid ? 128 : 64, paid ? 61 : 14)
  doc.setFontSize(9)
  doc.setFont('helvetica', 'bold')
  doc.text(paid ? '✓ PAYEE' : 'EN ATTENTE', marginX + 14, y, { align: 'center' })
  y += 14

  const colWidth = (pageWidth - marginX * 2) / 2
  doc.setTextColor(120)
  doc.setFontSize(9)
  doc.text('FACTURE A', marginX, y)
  doc.text('PRESTATAIRE', marginX + colWidth, y)
  y += 6
  doc.setTextColor(20)
  doc.setFontSize(12)
  doc.setFont('helvetica', 'bold')
  doc.text(data.clientName, marginX, y)
  doc.text(data.providerName, marginX + colWidth, y)
  doc.setFont('helvetica', 'normal')
  y += 12

  doc.setTextColor(120)
  doc.setFontSize(9)
  doc.text('DETAILS DE LA MISSION', marginX, y)
  y += 5
  doc.setDrawColor(230)
  doc.setFillColor(245, 246, 248)
  doc.roundedRect(marginX, y, pageWidth - marginX * 2, 24, 2, 2, 'FD')
  y += 7
  drawRow(doc, marginX + 6, pageWidth - marginX - 6, y, 'Service', data.requestTitle)
  y += 7
  drawRow(doc, marginX + 6, pageWidth - marginX - 6, y, 'Categorie', data.requestCategory || '—')
  y += 7
  drawRow(doc, marginX + 6, pageWidth - marginX - 6, y, 'Date', new Date(data.createdAt).toLocaleDateString('fr-CA'))
  y += 15

  doc.setTextColor(120)
  doc.setFontSize(9)
  doc.text('DETAIL DES MONTANTS', marginX, y)
  y += 5
  doc.setDrawColor(220)
  doc.roundedRect(marginX, y, pageWidth - marginX * 2, 32, 2, 2, 'D')
  y += 7
  drawRow(doc, marginX + 6, pageWidth - marginX - 6, y, 'Montant total', `${data.amount.toFixed(2)}$`)
  y += 8
  drawRow(doc, marginX + 6, pageWidth - marginX - 6, y, 'Commission plateforme (10%)', `-${data.platformFee.toFixed(2)}$`, [220, 38, 38])
  y += 4
  doc.setDrawColor(230)
  doc.line(marginX + 6, y, pageWidth - marginX - 6, y)
  y += 7
  drawRow(doc, marginX + 6, pageWidth - marginX - 6, y, 'Montant prestataire', `+${data.providerAmount.toFixed(2)}$`, [21, 128, 61], true)

  y += 24
  doc.setDrawColor(230)
  doc.line(marginX, y, pageWidth - marginX, y)
  y += 8
  doc.setTextColor(150)
  doc.setFontSize(9)
  doc.setFont('helvetica', 'normal')
  doc.text('© 2026 SOS-BESOIN · Tous droits reserves', pageWidth / 2, y, { align: 'center' })

  doc.save(`${data.invoiceNumber}.pdf`)
}

function drawRow(
  doc: jsPDF,
  xLeft: number,
  xRight: number,
  y: number,
  label: string,
  value: string,
  color: [number, number, number] = [30, 30, 30],
  bold = false
) {
  doc.setFont('helvetica', 'normal')
  doc.setFontSize(10)
  doc.setTextColor(100)
  doc.text(label, xLeft, y)
  doc.setFont('helvetica', bold ? 'bold' : 'normal')
  doc.setTextColor(color[0], color[1], color[2])
  doc.text(value, xRight, y, { align: 'right' })
}
