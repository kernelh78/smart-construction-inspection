from datetime import datetime, timedelta
from typing import List, Dict, Any
from sqlalchemy import func
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import cm
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer, PageBreak
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT
from sqlalchemy.orm import Session
from app.models import Site, Inspection, Defect, User


class ReportGenerator:
    """PDF 보고서 생성기"""
    
    def __init__(self, db: Session):
        self.db = db
        self.styles = getSampleStyleSheet()
        
        # 커스텀 스타일 추가
        self.styles.add(ParagraphStyle(
            name='CustomTitle',
            parent=self.styles['Title'],
            fontSize=16,
            textColor=colors.HexColor('#1a365d'),
            spaceAfter=20
        ))
        
        self.styles.add(ParagraphStyle(
            name='CustomHeading1',
            parent=self.styles['Heading1'],
            fontSize=14,
            textColor=colors.HexColor('#2d3748'),
            spaceBefore=15,
            spaceAfter=8
        ))
        
        self.styles.add(ParagraphStyle(
            name='CustomHeading2',
            parent=self.styles['Heading2'],
            fontSize=12,
            textColor=colors.HexColor('#4a5568'),
            spaceBefore=10,
            spaceAfter=5
        ))
        
        self.styles.add(ParagraphStyle(
            name='CustomBody',
            parent=self.styles['BodyText'],
            fontSize=10,
            leading=14
        ))
    
    def _get_date_range(self, days: int = 7) -> tuple:
        """날짜 범위 계산"""
        end_date = datetime.now()
        start_date = end_date - timedelta(days=days)
        return start_date, end_date
    
    def _get_sites_count(self) -> int:
        """총 현장 수"""
        return self.db.query(Site).count()
    
    def _get_inspections_count(self, start_date: datetime, end_date: datetime) -> int:
        """기간 내 점검 수"""
        return self.db.query(Inspection).filter(
            Inspection.inspected_at >= start_date,
            Inspection.inspected_at <= end_date
        ).count()
    
    def _get_defects_stats(self, start_date: datetime, end_date: datetime) -> Dict[str, int]:
        """기간 내 결함 통계"""
        defects = self.db.query(Defect).filter(
            Defect.created_at >= start_date,
            Defect.created_at <= end_date
        ).all()
        
        stats = {
            'total': len(defects),
            'minor': sum(1 for d in defects if d.severity == 'minor'),
            'major': sum(1 for d in defects if d.severity == 'major'),
            'critical': sum(1 for d in defects if d.severity == 'critical'),
            'resolved': sum(1 for d in defects if d.resolved_at is not None),
            'pending': sum(1 for d in defects if d.resolved_at is None)
        }
        return stats
    
    def _get_top_defect_types(self, limit: int = 5) -> List[Dict[str, Any]]:
        """상위 결함 유형"""
        results = self.db.query(
            Defect.description,
            func.count().label('count')
        ).group_by(Defect.description).order_by(func.count().desc()).limit(limit).all()
        
        return [{'description': r[0], 'count': r[1]} for r in results]
    
    def _get_recent_inspections(self, limit: int = 10) -> List[Inspection]:
        """최근 점검 기록"""
        return self.db.query(Inspection).order_by(
            Inspection.inspected_at.desc()
        ).limit(limit).all()
    
    def generate_daily_report(self, target_date: datetime = None) -> bytes:
        """일일 보고서 생성"""
        if target_date is None:
            target_date = datetime.now()
        
        start_date = target_date.replace(hour=0, minute=0, second=0, microsecond=0)
        end_date = target_date.replace(hour=23, minute=59, second=59, microsecond=999999)
        
        # 데이터 수집
        sites_count = self._get_sites_count()
        inspections_count = self._get_inspections_count(start_date, end_date)
        defects_stats = self._get_defects_stats(start_date, end_date)
        recent_inspections = self._get_recent_inspections(10)
        
        # PDF 생성
        from io import BytesIO
        buffer = BytesIO()
        
        doc = SimpleDocTemplate(
            buffer,
            pagesize=A4,
            rightMargin=2*cm,
            leftMargin=2*cm,
            topMargin=2*cm,
            bottomMargin=2*cm
        )
        
        story = []
        
        # 제목
        story.append(Paragraph("스마트 건설 감리 시스템", self.styles['CustomTitle']))
        story.append(Paragraph(f"일일 보고서 ({target_date.strftime('%Y-%m-%d')})", 
                             self.styles['CustomHeading1']))
        story.append(Spacer(1, 0.5*cm))
        
        # 요약 정보
        story.append(Paragraph("1. 요약 정보", self.styles['CustomHeading2']))
        
        summary_data = [
            ['항목', '값'],
            ['총 현장 수', str(sites_count)],
            ['오늘 점검 수', str(inspections_count)],
            ['오늘 발생 결함', str(defects_stats['total'])],
            ['해결된 결함', str(defects_stats['resolved'])],
            ['미해결 결함', str(defects_stats['pending'])]
        ]
        
        summary_table = Table(summary_data, colWidths=[8*cm, 8*cm])
        summary_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#1a365d')),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 12),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
            ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
            ('GRID', (0, 0), (-1, -1), 1, colors.black)
        ]))
        
        story.append(summary_table)
        story.append(Spacer(1, 1*cm))
        
        # 결함 통계
        story.append(Paragraph("2. 결함 통계", self.styles['CustomHeading2']))
        
        defect_data = [
            ['구분', '건수'],
            ['전체 결함', str(defects_stats['total'])],
            ['소규모 (Minor)', str(defects_stats['minor'])],
            ['중규모 (Major)', str(defects_stats['major'])],
            ['대규모 (Critical)', str(defects_stats['critical'])],
            ['해결된 결함', str(defects_stats['resolved'])],
            ['미해결 결함', str(defects_stats['pending'])]
        ]
        
        defect_table = Table(defect_data, colWidths=[8*cm, 8*cm])
        defect_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#2d3748')),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 12),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
            ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
            ('GRID', (0, 0), (-1, -1), 1, colors.black)
        ]))
        
        story.append(defect_table)
        story.append(Spacer(1, 1*cm))
        
        # 최근 점검 기록
        story.append(Paragraph("3. 최근 점검 기록", self.styles['CustomHeading2']))
        
        if recent_inspections:
            inspection_data = [['날짜', '현장명', '점검자', '점검카테고리', '결과']]
            
            for inspection in recent_inspections:
                site = self.db.query(Site).filter(Site.id == inspection.site_id).first()
                inspector = self.db.query(User).filter(User.id == inspection.inspector_id).first()
                
                site_name = site.name if site else "알 수 없음"
                inspector_name = inspector.name if inspector else "알 수 없음"
                status = "합격" if inspection.status == "pass" else "미합격"
                
                inspection_data.append([
                    inspection.inspected_at.strftime('%Y-%m-%d %H:%M'),
                    site_name,
                    inspector_name,
                    inspection.category,
                    status
                ])
            
            inspection_table = Table(inspection_data, colWidths=[4*cm, 4*cm, 3*cm, 3*cm, 2*cm])
            inspection_table.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#4a5568')),
                ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
                ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
                ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                ('FONTSIZE', (0, 0), (-1, 0), 10),
                ('BOTTOMPADDING', (0, 0), (-1, 0), 8),
                ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
                ('GRID', (0, 0), (-1, -1), 1, colors.black),
                ('FONTSIZE', (0, 1), (-1, -1), 9)
            ]))
            
            story.append(inspection_table)
        else:
            story.append(Paragraph("오늘의 점검 기록이 없습니다.", self.styles['CustomBody']))
        
        story.append(Spacer(1, 1*cm))
        
        # Footer
        story.append(PageBreak())
        story.append(Paragraph(f"보고서 생성일: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}", 
                             self.styles['CustomBody']))
        story.append(Paragraph("스마트 건설 감리 시스템 - 자동 생성 보고서", 
                             self.styles['CustomBody']))
        
        doc.build(story)
        
        pdf = buffer.getvalue()
        buffer.close()
        
        return pdf
    
    def generate_weekly_report(self, weeks: int = 1) -> bytes:
        """주간 보고서 생성"""
        end_date = datetime.now()
        start_date = end_date - timedelta(weeks=weeks)
        
        # 데이터 수집
        sites_count = self._get_sites_count()
        inspections_count = self._get_inspections_count(start_date, end_date)
        defects_stats = self._get_defects_stats(start_date, end_date)
        
        from io import BytesIO
        buffer = BytesIO()
        
        doc = SimpleDocTemplate(
            buffer,
            pagesize=A4,
            rightMargin=2*cm,
            leftMargin=2*cm,
            topMargin=2*cm,
            bottomMargin=2*cm
        )
        
        story = []
        
        # 제목
        story.append(Paragraph("스마트 건설 감리 시스템", self.styles['CustomTitle']))
        story.append(Paragraph(f"주간 보고서 ({start_date.strftime('%Y-%m-%d')} ~ {end_date.strftime('%Y-%m-%d')})", 
                             self.styles['CustomHeading1']))
        story.append(Spacer(1, 0.5*cm))
        
        # 요약 정보
        story.append(Paragraph("1. 요약 정보", self.styles['CustomHeading2']))
        
        summary_data = [
            ['항목', '값'],
            ['총 현장 수', str(sites_count)],
            ['주간 점검 수', str(inspections_count)],
            ['주간 발생 결함', str(defects_stats['total'])],
            ['해결된 결함', str(defects_stats['resolved'])],
            ['미해결 결함', str(defects_stats['pending'])]
        ]
        
        summary_table = Table(summary_data, colWidths=[8*cm, 8*cm])
        summary_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#1a365d')),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 12),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
            ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
            ('GRID', (0, 0), (-1, -1), 1, colors.black)
        ]))
        
        story.append(summary_table)
        story.append(Spacer(1, 1*cm))
        
        # 결함 통계
        story.append(Paragraph("2. 결함 통계", self.styles['CustomHeading2']))
        
        defect_data = [
            ['구분', '건수'],
            ['전체 결함', str(defects_stats['total'])],
            ['소규모 (Minor)', str(defects_stats['minor'])],
            ['중규모 (Major)', str(defects_stats['major'])],
            ['대규모 (Critical)', str(defects_stats['critical'])],
            ['해결된 결함', str(defects_stats['resolved'])],
            ['미해결 결함', str(defects_stats['pending'])]
        ]
        
        defect_table = Table(defect_data, colWidths=[8*cm, 8*cm])
        defect_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#2d3748')),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 12),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
            ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
            ('GRID', (0, 0), (-1, -1), 1, colors.black)
        ]))
        
        story.append(defect_table)
        story.append(Spacer(1, 1*cm))
        
        # Footer
        story.append(PageBreak())
        story.append(Paragraph(f"보고서 생성일: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}", 
                             self.styles['CustomBody']))
        story.append(Paragraph("스마트 건설 감리 시스템 - 자동 생성 보고서", 
                             self.styles['CustomBody']))
        
        doc.build(story)
        
        pdf = buffer.getvalue()
        buffer.close()
        
        return pdf