// Inline SVG icons — lucide-style. Pass size + className.
const Svg = ({ size = 18, children, ...rest }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...rest}>
    {children}
  </svg>
);

const Icon = {
  Alert: (p) => <Svg {...p}><path d="M12 9v4"/><path d="M12 17h.01"/><path d="M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/></Svg>,
  Arrow: (p) => <Svg {...p}><path d="M5 12h14"/><path d="m12 5 7 7-7 7"/></Svg>,
  ArrowUR: (p) => <Svg {...p}><path d="M7 17 17 7"/><path d="M7 7h10v10"/></Svg>,
  Check: (p) => <Svg {...p}><path d="M20 6 9 17l-5-5"/></Svg>,
  Shield: (p) => <Svg {...p}><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></Svg>,
  Bolt: (p) => <Svg {...p}><path d="M13 2 3 14h9l-1 8 10-12h-9l1-8z"/></Svg>,
  Clock: (p) => <Svg {...p}><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></Svg>,
  Star: (p) => <Svg {...p}><path d="M12 2l3 7 7 .8-5.4 4.7L18.5 22 12 17.7 5.5 22l1.9-7.5L2 9.8 9 9z" fill="currentColor"/></Svg>,
  Plus: (p) => <Svg {...p}><path d="M12 5v14"/><path d="M5 12h14"/></Svg>,
  Cpu: (p) => <Svg {...p}><rect x="4" y="4" width="16" height="16" rx="2"/><rect x="9" y="9" width="6" height="6"/><path d="M9 2v2"/><path d="M15 2v2"/><path d="M9 20v2"/><path d="M15 20v2"/><path d="M2 9h2"/><path d="M2 15h2"/><path d="M20 9h2"/><path d="M20 15h2"/></Svg>,
  Music: (p) => <Svg {...p}><path d="M9 18V5l12-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="18" cy="16" r="3"/></Svg>,
  Wrench: (p) => <Svg {...p}><path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z"/></Svg>,
  Truck: (p) => <Svg {...p}><path d="M14 18V6a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2v11a1 1 0 0 0 1 1h2"/><path d="M15 18H9"/><path d="M19 18h2a1 1 0 0 0 1-1v-3.65a1 1 0 0 0-.22-.624l-3.48-4.35A1 1 0 0 0 17.52 8H14"/><circle cx="17" cy="18" r="2"/><circle cx="7" cy="18" r="2"/></Svg>,
  Book: (p) => <Svg {...p}><path d="M4 19.5v-15A2.5 2.5 0 0 1 6.5 2H20v20H6.5a2.5 2.5 0 0 1 0-5H20"/></Svg>,
  Pen: (p) => <Svg {...p}><path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5z"/></Svg>,
  Globe: (p) => <Svg {...p}><circle cx="12" cy="12" r="10"/><path d="M12 2a14.5 14.5 0 0 0 0 20a14.5 14.5 0 0 0 0-20"/><path d="M2 12h20"/></Svg>,
  Gavel: (p) => <Svg {...p}><path d="m14 13-7.5 7.5c-.83.83-2.17.83-3 0 0 0 0 0 0 0a2.12 2.12 0 0 1 0-3L11 10"/><path d="m16 16 6-6"/><path d="m8 8 6-6"/><path d="m9 7 8 8"/><path d="m21 11-8-8"/></Svg>,
  Heart: (p) => <Svg {...p}><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></Svg>,
  Search: (p) => <Svg {...p}><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></Svg>,
  User: (p) => <Svg {...p}><circle cx="12" cy="8" r="4"/><path d="M20 21a8 8 0 0 0-16 0"/></Svg>,
  Users: (p) => <Svg {...p}><circle cx="9" cy="8" r="4"/><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="17" cy="6" r="3"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/></Svg>,
  Send: (p) => <Svg {...p}><path d="M22 2 11 13"/><path d="M22 2l-7 20-4-9-9-4z"/></Svg>,
  Eye: (p) => <Svg {...p}><path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7z"/><circle cx="12" cy="12" r="3"/></Svg>,
  Trend: (p) => <Svg {...p}><polyline points="22 7 13.5 15.5 8.5 10.5 2 17"/><polyline points="16 7 22 7 22 13"/></Svg>,
  Tag: (p) => <Svg {...p}><path d="M20.59 13.41l-7.17 7.17a2 2 0 0 1-2.83 0L2 12V2h10l8.59 8.59a2 2 0 0 1 0 2.82z"/><circle cx="7" cy="7" r="1"/></Svg>,
  Twitter: (p) => <Svg {...p}><path d="M4 4l11.5 16h4L8 4z"/><path d="M4 20l7.5-8.5"/><path d="m13.5 11.5 6.5-7.5"/></Svg>,
  Linked: (p) => <Svg {...p}><path d="M4 4h4v4H4z" fill="currentColor"/><path d="M4 10h4v10H4z" fill="currentColor"/><path d="M10 10h4v2c1-1.5 2.5-2.5 4.5-2.5C21 9.5 22 11.5 22 14v6h-4v-5c0-1.5-.5-2.5-2-2.5s-2 1-2 2.5v5h-4z" fill="currentColor"/></Svg>,
  Insta: (p) => <Svg {...p}><rect x="3" y="3" width="18" height="18" rx="5"/><circle cx="12" cy="12" r="4"/><circle cx="17.5" cy="6.5" r="1" fill="currentColor"/></Svg>,
};

window.Icon = Icon;
