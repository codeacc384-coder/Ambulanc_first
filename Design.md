# Design.md — Ambulance First
### Emergency Medical Transport Platform — UI/UX Design Specification

> **Scope:** Admin Portal · Driver Console · Customer Care Operations Portal
> **Framework:** Flutter (Material 3, useMaterial3: true)
> **Last Updated:** September 2026

---

## Table of Contents

1. [Design Philosophy](#1-design-philosophy)
2. [Shared Design System Tokens](#2-shared-design-system-tokens)
3. [Admin Portal Design](#3-admin-portal-design)
4. [Driver Console Design](#4-driver-console-design)
5. [Customer Care Portal Design](#5-customer-care-portal-design)
6. [Cross-Portal Design Rules](#6-cross-portal-design-rules)
7. [Semantic Color Usage Guide](#7-semantic-color-usage-guide)
8. [Accessibility & Responsiveness](#8-accessibility--responsiveness)

---

## 1. Design Philosophy

Ambulance First is a **clinical-grade, high-stakes emergency transport platform**. Every design decision must reflect:

| Principle | Description |
|---|---|
| **Operational Clarity** | Critical information must be immediately scannable at a glance — no visual clutter. |
| **Trust & Authority** | Clinical Cobalt (#0369A1) is the primary brand identity — professional, reliable, calm under pressure. |
| **High-Density Data** | Screens carry real-time telemetry, booking IDs, patient vitals, GPS coordinates, and queue metrics — displayed without cognitive overload. |
| **Role Specificity** | Each portal is tailored to its operator's mental model: Admin = oversight, Driver = action, Customer Care = triage. |
| **Zero Ambiguity** | Status badges, urgency pips, semantic colors, and JetBrains Mono numerics provide unambiguous state communication. |
| **Light-Mode First** | All portals use a clinical light-mode canvas (#F8F9FF) with dark-chrome nav accents for focus areas. |

---

## 2. Shared Design System Tokens

### 2.1 Color Palette

All three portals share the same foundational color contract defined in StitchTheme / DriverColors / CustomerCareColors. Derived from the **Emergency Response Console** Stitch design system.

#### Primary Brand — Clinical Cobalt

| Token | Hex | Usage |
|---|---|---|
| primary | #00507D | Deep brand blue; text on light bg |
| primaryContainer | #0369A1 | Primary interactive elements, CTA buttons, app bars |
| onPrimary | #FFFFFF | Text on primary-filled surfaces |
| onPrimaryContainer | #CBE4FF | Text on dark primary containers |
| primaryFixed | #CDE5FF | Light tint for badges, chips bg |
| primaryFixedDim | #94CCFF | Hovered/dimmed primary state |
| onPrimaryFixed | #001D32 | Text on primaryFixed surfaces |
| inversePrimary | #94CCFF | Inverse (dark) primary — for HUD overlays |

#### Secondary — Operational Emerald (Available / Verified)

| Token | Hex | Usage |
|---|---|---|
| secondary | #006C4A | Available/on-duty status, verified state |
| secondaryContainer | #82F5C1–#9AF1C6 | Verified badge bg, emerald chip bg |
| onSecondary | #FFFFFF | Text on secondary |
| secondaryFixed | #85F8C4 | Fixed emerald tint |

#### Error / Alert — Code Red (Crimson)

| Token | Hex | Usage |
|---|---|---|
| error | #DC2626 | Critical alerts, Code Red badges, ETA labels, CRITICAL urgency pips |
| errorContainer | #FFDAD6 | Code Red background chips |
| onError | #FFFFFF | Text on error |
| onErrorContainer | #93000A | Text on errorContainer |

#### Warning — Urgent Amber

| Token | Hex | Usage |
|---|---|---|
| warning | #D97706 | In-transit, pending, follow-up badges |
| warningContainer | #FEF3C7–#FFFBEB | Warning chip backgrounds |
| onWarning | #92400E | Text on warningContainer |

#### Surface Hierarchy (Light-Mode Canvas)

| Token | Hex | Usage |
|---|---|---|
| background / surface | #F8F9FF | Scaffold background |
| surfaceContainerLowest | #FFFFFF | Cards, modals, form panels |
| surfaceContainerLow | #EFF4FF | Input fill, hover states |
| surfaceContainer | #E5EEFF | Chip bg, divider areas |
| surfaceContainerHigh | #DCE9FF | Triage ticker bg, selected states |
| surfaceContainerHighest | #D3E4FE | Deepest container for dense grids |
| surfaceDim | #CBDBF5–#D3E4FE | Muted surface, radar card bg |

#### Inverse — Dark Chrome (HUDs & Nav)

| Token | Hex | Usage |
|---|---|---|
| inverseSurface | #213145 | Drawer overlays, dark telemetry bg |
| inverseSurfaceDark | #131D2A | Driver HUD bar |
| inverseOnSurface | #EAF1FF | Text on inverse surfaces |
| commandNavDark | #0B132B | Admin command drawer bg, CC tactical nav |
| commandNavMarine | #1C2541 | Admin nav accent |

#### Customer Care — Tertiary Lavender (Specialist / Pediatric)

| Token | Hex | Usage |
|---|---|---|
| tertiary (CC) | #392CD1 | Specialist / PICU indicator |
| tertiaryContainer | #534BE9 | Lavender badge bg |
| tertiaryFixed | #E2DFFF | Light lavender tint |

#### Status / Telemetry Indicators (Driver)

| Token | Hex | Usage |
|---|---|---|
| liveTelemetry | #10B981 | Live GPS ping indicator |
| staleTelemetry | #F59E0B | Stale / delayed telemetry |
| unavailableTelemetry | #EF4444 | GPS unavailable |

#### Content / Outline Colors

| Token | Hex | Usage |
|---|---|---|
| onSurface | #0B1C30 | Primary text — all portals |
| onSurfaceVariant | #40474F | Secondary text, labels, subtitles |
| outline | #707881 | Timestamps, muted labels |
| outlineVariant | #C0C7D1 | Card borders, divider lines |
| borderSubtle | #E2E8F0 | Hairline card edges (Admin) |

---

### 2.2 Typography

Each portal uses a **two-typeface system**: a humanist UI sans-serif for reading, and **JetBrains Mono** for all telemetry, IDs, codes, and timestamps.

#### Admin Portal (StitchTheme)
- **UI Font:** Inter (Google Fonts) — used for all headlines, body, and buttons
- **Telemetry Font:** JetBrains Mono — used for booking IDs, timestamps, CAD codes

| Style | Font | Size | Weight | Usage |
|---|---|---|---|---|
| displayLg | Inter | 30px | 700 | Hero stats on dashboard |
| displayLgMobile | Inter | 24px | 700 | Mobile dashboard headings |
| headlineLg | Inter | 22px | 600 | Section titles |
| headlineMd | Inter | 18px | 600 | Card headings |
| headlineSm | Inter | 15px | 600 | Sub-section headers |
| bodyLg | Inter | 15px | 400 | Primary narrative |
| bodyMd | Inter | 13px | 400 | Supporting content |
| bodySm | Inter | 12px | 400 | Captions, audit log details |
| labelLg | JetBrains Mono | 13px | 600 | Booking IDs, CAD codes |
| labelMd | JetBrains Mono | 11px | 500 | Operational labels |
| labelSm | JetBrains Mono | 10px | 500 | Timestamps, sub-codes |

#### Driver Console (DriverTextStyles)
- **UI Font:** Public Sans (Google Fonts)
- **Telemetry Font:** JetBrains Mono

| Style | Font | Size | Weight | Usage |
|---|---|---|---|---|
| headlineLarge | Public Sans | 24px | 700 | Driver login header |
| headlineMedium | Public Sans | 20px | 700 | Section headings |
| headlineSmall | Public Sans | 16px | 700 | Mission sub-headers |
| titleMedium | Public Sans | 15px | 600 | Patient name labels |
| bodyLarge | Public Sans | 15px | 400 | Route descriptions |
| bodyMedium | Public Sans | 13px | 400 | Supporting content |
| bodySmall | Public Sans | 11px | 400 | Captions |
| button | Public Sans | 14px | 700 | All CTA labels |
| telemetryLarge | JetBrains Mono | 24px | 800 | Speed, ETA primary displays |
| telemetryMedium | JetBrains Mono | 18px | 700 | KPI values |
| telemetrySmall | JetBrains Mono | 13px | 600 | Secondary telemetry |
| telemetryMicro | JetBrains Mono | 10px | 600 | HUD micro-labels, pilot IDs |
| bookingId | JetBrains Mono | 12px | 700 | Booking ID display |
| timestamp | JetBrains Mono | 11px | 500 | Time readouts |

#### Customer Care Portal (CustomerCareTextStyles)
- **UI Font:** Inter (Google Fonts)
- **Telemetry Font:** JetBrains Mono

| Style | Font | Size | Weight | Usage |
|---|---|---|---|---|
| headlineLg | Inter | 28px | 700 | Portal header, login title |
| headlineLgMobile | Inter | 22px | 700 | Mobile dashboard headings |
| headlineMd | Inter | 20px | 600 | Section titles |
| headlineSm | Inter | 16px | 600 | Card headings, queue labels |
| bodyLg | Inter | 15px | 400 | Clinical narrative |
| bodyMd | Inter | 13px | 400 | Form fields, descriptions |
| bodySm | Inter | 12px | 400 | Captions, empty state messages |
| telemetryDisplay | JetBrains Mono | 18px | 700 | Live radar / telemetry values |
| labelLg | JetBrains Mono | 13px | 600 | Booking IDs, CC codes |
| labelMd | JetBrains Mono | 11px | 600 | Operational labels |
| labelSm | JetBrains Mono | 10px | 500 | Timestamps, sub-codes |

---

### 2.3 Spacing & Border Radii

#### Spacing Scale

| Token | Value | Usage |
|---|---|---|
| spaceXs | 4px | Icon-to-text gaps, tight badge padding |
| spaceSm | 8px | Between card rows, between small chips |
| spaceMd | 12px | Card internal padding, between sections |
| spaceLg | 20px | Between major sections on a screen |
| spaceXl | 32px | Hero section spacing |
| margin | 16px | Standard horizontal screen padding |

#### Border Radii

| Token | Value | Usage |
|---|---|---|
| radiusSm | 4px | Finance boxes, tight chips |
| radiusMd | 8px | Tags, compact chips |
| radiusLg | 12px | Standard cards, standard containers |
| radiusXl | 16px | Large cards, login panels |
| radiusPill | 9999px | Status badges, filter pills |

> Driver-specific: Cards use 18–22px radius for a more rounded mobile feel.

---

### 2.4 Elevation & Shadows

The design uses **zero Material elevation** on cards. Visual hierarchy is achieved through **surface container layering** and **hairline borders**, not drop shadows.

Subtle box shadows are reserved for focal elements only (login panels, active mission card).

---

## 3. Admin Portal Design

### 3.1 Identity & Theme

| Property | Value |
|---|---|
| Theme class | StitchTheme |
| Design system name | Emergency Medical Fleet Operations Portal |
| Scaffold background | #F8F9FF |
| Card style | Zero elevation, borderSubtle hairline border (#E2E8F0), 12px radius |
| AppBar | Flat, background-colored, no elevation |
| Font | Inter (UI) + JetBrains Mono (telemetry) |
| Primary color | #0369A1 (Clinical Cobalt) |
| Nav chrome | #0B132B (Command Dark) / #1C2541 (Command Marine) |
| Target platform | Web / tablet / desktop |

### 3.2 Navigation Shell

Shell class: AdminShell (lib/roles/admin/screens/admin_shell.dart)

Layout:
- Fixed top: StitchHeader [Title] [User] [Sync] [Drawer Menu]
- Contextual: LinearProgressIndicator or Error Banner
- Scrollable: IndexedStack (Page Content)
- Fixed bottom: StitchBottomNav [Tab icons] [More]
- End Drawer: StitchCommandDrawer (dark chrome, #0B132B)

Navigation Tabs (8 items):

| Index | Tab Label | Screen |
|---|---|---|
| 0 | Dashboard | AdminDashboardScreen |
| 1 | Bookings | AdminBookingsScreen |
| 2 | Fleet | AdminFleetScreen |
| 3 | Staff | AdminStaffScreen |
| 4 | Finance | AdminQuotationsScreen |
| 5 | Reports | AdminReportsScreen |
| 6 | Audit | AdminAuditScreen |
| 7 | Pricing Settings | AdminPricingScreen |

Booking 360 Detail is a full-screen overlay pushed imperatively (replaces shell content without changing tab index).

### 3.3 Screen Inventory

#### Dashboard (AdminDashboardScreen)

A command-center overview screen with 7 functional sections stacked vertically:

| # | Section | Key Data |
|---|---|---|
| 1 | Live Triage Ticker | Active bookings cycling every 4s with pause/play control via AnimatedSwitcher |
| 2 | Executive KPI Grid (StitchMetricCard x2) | Total Bookings, Active Trips (sub-labels: Transit / Started / Picked Up) |
| 3 | Fleet Readiness Gauge (StitchFleetReadinessCard) | Available / Total ambulances count |
| 4 | Revenue & Quotations Matrix (_FinanceBox x4) | Quoted Pipeline, Accepted Orders, Paid/Recognized, Outstanding |
| 5 | Live Active Bookings Feed (_ActiveBookingItem list) | Patient, route, ETA, urgency pip, status badge |
| 6 | Medical Staff Readiness (_StaffRosterRow x3) | Doctors / EMTs / Drivers — available vs. total |
| 7 | Governance & Audit Feed | Recent 3 audit log entries — severity icon, entity ID, timestamp delta |

Triage Ticker:
- surfaceContainerHigh background, red dot indicator, "TRIAGE TICKER:" label in error color
- AnimatedSwitcher for smooth message transitions, pause/play toggle

Active Booking Item:
- Left urgency pip: error (CRITICAL) or warning (URGENT) — 5px wide vertical bar
- Booking ID in JetBrains Mono + relative timestamp + status badge pill
- Patient avatar (initials, primaryContainer bg) + name/age/gender + ETA in error color
- Route row: pickup -> destination + ambulance ID

#### Bookings (AdminBookingsScreen)

Full booking list with search, status filter tabs, and booking cards. Taps open AdminBookingDetailScreen for 360-degree view.

#### Fleet (AdminFleetScreen)

Fleet registry with ambulance cards: availability status, type, registration, assigned driver. Register new fleet via AdminFleetRegisterScreen.

#### Staff (AdminStaffScreen)

Staff roster with role tabs (Doctors / EMTs / Drivers). Availability status pills, contact info, assignment summary.

#### Finance (AdminQuotationsScreen)

Quotation pipeline list with financial breakdown: quoted -> accepted -> paid -> outstanding.

#### Reports (AdminReportsScreen)

Analytics report view with category filters for drill-down to the Bookings tab.

#### Audit (AdminAuditScreen)

Full audit log trail. Severity-coded entries: CRITICAL (error red), WARNING (secondary), INFO (tertiary/emerald).

#### Pricing (AdminPricingScreen)

Pricing configuration settings management screen.

### 3.4 Component Patterns

#### StitchMetricCard

Structure: [Icon] Title | LIVE badge pill | VALUE (JetBrains Mono displayLg) | Subtitle (labelSm)
- Zero elevation card, surfaceContainerLowest bg, hairline border
- Tappable to navigate to relevant tab

#### StitchStatusBadge

Pill-shaped status label derived from BookingStatus enum:
- In Transit -> Amber (warning)
- Pickup Started -> Primary blue
- Patient Picked Up -> Emerald (tertiary)
- Completed -> Secondary green
- Cancelled -> Error red

#### Finance Box (_FinanceBox)

Label (labelSm, outline color) | Value (labelLg, semantic color) | Subtitle (bodySm, muted)
Background: surfaceContainerLow, radiusSm

#### Staff Roster Row (_StaffRosterRow)

Role icon + title + subtitle on left. Available/total count on right with emerald accent for available.

---

## 4. Driver Console Design

### 4.1 Identity & Theme

| Property | Value |
|---|---|
| Theme class | DriverTheme |
| Colors class | DriverColors |
| Text styles class | DriverTextStyles |
| Design system name | Emergency Response Console |
| Scaffold background | #F8F9FF |
| Card border radius | 16px |
| Button border radius | 14px |
| Input border radius | 12px |
| Font | Public Sans (UI) + JetBrains Mono (telemetry) |
| Primary color | #0369A1 (Clinical Cobalt) |
| Secondary | #006C4A (Operational Emerald) |
| Tertiary / Error | #DC2626 (Code Red) |
| Target platform | Mobile (Android/iOS) |

Login Screen:
- Background: tri-color diagonal gradient (background -> surfaceContainerLow -> surfaceContainerHigh)
- Card: 22px radius, hairline border, soft shadow
- Brand block: primaryContainer square icon (local_shipping_rounded, 56x56), glow shadow
- "Ambulance First" (headlineMedium, primary) + "24/7 EMERGENCY PILOT NETWORK" (telemetryMicro)

### 4.2 Navigation Shell

Shell class: DriverShell (lib/features/driver/presentation/shell/driver_shell.dart)

Layout:
- Fixed top: HUD Telemetry Bar (vehicle speed, GPS status)
- Scrollable: Screen Content
- Fixed bottom: Bottom Tab Navigation (4 tabs)

Navigation Tabs (4 items):

| Tab | Icon | Screen |
|---|---|---|
| Dashboard | home_rounded | DriverDashboardScreen |
| Active Trip | navigation_rounded | DriverActiveTripScreen |
| Assignments | assignment_rounded | DriverAssignmentsScreen |
| Profile | person_rounded | DriverProfileScreen |

Trip History accessible from Profile or Assignments tab.

### 4.3 Screen Inventory

#### Dashboard (DriverDashboardScreen)

Mobile-first scrollable screen with 4 sections:

**1. Pilot Identity Card**
- CircleAvatar (radius 26, primaryContainer bg, white initial letter)
- Name (headlineSmall) + PILOT ID & ambulance number (telemetryMicro, primaryContainer)
- License number + expiry (bodySmall)
- DriverDutySwitcher below divider

**2. Active Mission Card** (when active trip exists)
- primaryContainer border and header bar strip
- Header: "ACTIVE MISSION IN PROGRESS" + Booking ID (white, JetBrains Mono)
- Body: Patient name/age/gender, medical condition, route (pickup -> destination)
- Full-width CTA: "OPEN ACTIVE TRIP CONSOLE" (primaryContainer button, speed icon)

**2b. Standby Readiness Card** (no active trip)
- Emerald check icon + "Ready on Standby Depot" + unit number text

**3. Assigned Bookings Queue**
- Up to 2 previewed, View All link to AssignmentsScreen
- Each row: hospital icon box + booking ID + time chip + patient + route + START button

**4. Pilot Performance Stats**
- 3x _StatCard horizontal: Total Transports, Response Accuracy, Pilot Rating
- Each: icon (semantic color) + telemetryMedium value + telemetryMicro label

#### Active Trip (DriverActiveTripScreen)

Full-mission management screen:
- LiveMapViewport — GPS map with route overlay and recenter FAB
- TripStageStepper — stage progression with completed/active/upcoming node states
- HUDTelemetryBar — dark chrome bar with speed, GPS status, ETA, booking ID
- EmergencySOSModal — accessible at all times via persistent button

#### Assignments (DriverAssignmentsScreen)

Full list of assigned bookings. AssignmentCard widget per booking:
- Booking ID + time badges
- Patient details + pickup/drop route
- Status label + advance action button

#### Profile (DriverProfileScreen)

Driver profile: name, photo, license, ambulance assignment, rating. Links to trip history.

#### Trip History (DriverTripHistoryScreen)

Chronological list of past completed/cancelled trips with dates and patient summaries.

### 4.4 Component Patterns

#### DriverDutySwitcher

Segmented control: ON DUTY (emerald) | OFF DUTY (surface). Disabled when active trip exists.

#### AssignmentCard

[Hospital Icon Box] + BOOKING-ID (bookingId) + [TIME CHIP] (telemetryMicro) + Patient/route (bodySmall) + [ADVANCE] button (primary)

#### HUDTelemetryBar

Dark-chrome bar (inverseSurfaceDark #131D2A):
- Speed (telemetryLarge, white)
- GPS dot (live #10B981 / stale #F59E0B / unavailable #EF4444)
- ETA (telemetryMedium, inversePrimary)
- Booking ID (bookingId, muted)

#### LiveMapViewport

Full-width map with driver pin, destination marker, route polyline (primaryContainer), recenter FAB.

#### TripStageStepper

Vertical stepper: completed (emerald filled circle) / active (primary outlined, pulse) / upcoming (outline, muted).

#### EmergencySOSModal

Red-themed full-screen modal: large SOS button (#DC2626), contact dispatch/hospital quick-dial, incident report form.

#### QuickContactModal

Bottom sheet for quick-calling patient, caller, or hospital contacts during a trip.

---

## 5. Customer Care Portal Design

### 5.1 Identity & Theme

| Property | Value |
|---|---|
| Theme class | CustomerCareTheme |
| Colors class | CustomerCareColors |
| Text styles class | CustomerCareTextStyles |
| Design system name | Clinical High-Density Operations |
| Scaffold background | #F8F9FF |
| Card border radius | 12px (standard), 16px (panels) |
| Font | Inter (UI) + JetBrains Mono (telemetry) |
| Primary | #0369A1 (Clinical Cobalt) |
| Secondary | #006C4A (Operational Emerald) |
| Tertiary | #392CD1 (Specialist Lavender) — PICU/Pediatric |
| Tactical Nav bg | #0B132B, border #1E293B |
| Target platform | Web / tablet |

Login Screen:
- Centered card on background canvas (#F8F9FF)
- Card: surfaceContainerLowest bg, 16px radius, outlineVariant border, soft shadow
- Brand icon: primaryContainer square (headset_mic_rounded, 56x56, glow shadow)
- "Ambulance First" (headlineLg, primary) + "Customer Care Operations Portal" (labelMd, muted)
- Operator Agent ID field + Security Password field (show/hide toggle)
- CTA: "ENTER OPERATIONS PORTAL" (full-width primaryContainer button, 46px height)

### 5.2 Navigation Shell

Shell class: CustomerCareShell (lib/features/customer_care/presentation/shell/customer_care_shell.dart)

Layout:
- Fixed top: Tactical Header (Agent ID, Shift, Sync)
- Contextual: AgentShiftBanner if active shift
- Scrollable: Screen Content
- Fixed bottom: Bottom Tab Navigation (5 tabs)

Navigation Tabs (5 items):

| Tab | Icon | Screen |
|---|---|---|
| Dashboard | dashboard_rounded | CustomerCareDashboardScreen |
| New Intake | add_ic_call_rounded | NewBookingsIntakeScreen |
| Active Trips | monitor_heart_rounded | ActiveTripsScreen |
| Verified | task_alt_rounded | VerifiedBookingsScreen |
| Archive | inventory_2_rounded | AllBookingsArchiveScreen |

Pushed screens (not tabs):
- TeamLeadHandoverScreen — from Verified or Dashboard
- Booking360DetailsScreen — from any booking card
- CallVerificationConsoleScreen — from Dashboard triage cards

### 5.3 Screen Inventory

#### Dashboard (CustomerCareDashboardScreen)

High-density triage operations hub with 6 sections:

**1. Agent Shift Banner (AgentShiftBanner)**
- Left green accent border, surfaceContainerLow bg
- Agent name, CC ID, shift time, shift status label

**2. KPI Queue Cards Grid** — 2x2 on narrow, 1x4 on width > 580px (LayoutBuilder)

| Card | Accent Color | Badge | Interaction |
|---|---|---|---|
| New Inbound | error (#DC2626) | "2 Code Red" | Pulse animation; tap to filter |
| Pending Calls | warning (#D97706) | "1 Follow-up" | Tap to filter to pending |
| Verified | secondary (#006C4A) | "Ready" | Tap to filter to verified |
| Sent to Lead | primaryContainer (#0369A1) | "In Dispatch" | Tap to filter to handed-over |

Selected state: primaryContainer bg fill, white text.

**3. Search & Filter Ribbon**
- Full-width search input (12px radius, surfaceContainerLowest, no border ring)
- Placeholder: "Search Booking ID, patient, caller phone..."
- Filter chips: All . Code Red (red dot) . High Urgency (amber dot) . Pediatric (child icon) . ICU Required

**4. Triage Incident Queue Header**
- Emergency icon + "Triage Incident Queue" (headlineSm, w700)
- "Real-time sync: Active" (labelSm, muted, right-aligned)

**5. Incident Cards (TriageIncidentCard)** — Scrollable list, separated by 10px gaps

**6. Telemetry Radar Card (TelemetryRadarCard)** — Air corridor airspace animated widget at bottom of scroll

#### New Intake (NewBookingsIntakeScreen)

Structured form for logging a new emergency booking: caller info, patient profile, medical condition, pickup/destination address, priority selection, pediatric/ICU flags, submit action.

#### Active Trips (ActiveTripsScreen)

Real-time list of in-transit bookings with: live GPS telemetry access (LiveGPSTelemetryDialog), driver/ambulance assignment status, ETAs, BookingLifecycleTimeline.

#### Verified Bookings (VerifiedBookingsScreen)

Queue of CC-verified cases: verified timestamp, verifying agent name, priority badge, case notes preview, Send to Team Lead button.

#### Archive (AllBookingsArchiveScreen)

Complete historical booking archive with date filtering and status search.

#### Booking 360 Degree Details (Booking360DetailsScreen)

AppBar: Back arrow + "Dossier 360°: #ID" title + status badge chip (surfaceContainerHigh bg)

| Section | Icon | Content |
|---|---|---|
| Patient & Clinical Profile | person_rounded | Name, age/gender, acuity, condition, MRN, pediatric flag |
| Caller & Contact | phone_rounded | Caller name, phone, relationship |
| Route & Logistics | navigation_rounded | Pickup address, destination, region |
| Booking Timeline | timeline_rounded | BookingLifecycleTimeline widget |
| Verification Notes | verified_rounded | Checklist items + agent notes |

#### Call Verification Console (CallVerificationConsoleScreen)

- Caller info header + call-back button
- VerificationChecklistView — protocol checklist (ICU bed confirmed, route clear, etc.)
- CallOutcomeSelector — radio: Verified / Unable to Contact / Requires Escalation
- Submit verification action

#### Team Lead Handover (TeamLeadHandoverScreen)

- Case summary review panel
- Priority confirmation
- Handover notes text field
- "SEND TO TEAM LEAD" CTA (full-width primaryContainer button)

### 5.4 Component Patterns

#### KpiQueueCard

[Icon] Count (JetBrains Mono telemetryDisplay) | [Badge pill] | Title (headlineSm) | Subtitle (bodySm, muted)
Selected: primaryContainer bg fill, white text. hasPulse=true adds pulse animation to New Inbound card.

#### TriageIncidentCard

Left urgency pip (error=Code Red, warning=High, secondary=Normal, 4px wide) + card body:
- Row 1: #ID (JetBrains Mono) + Priority Badge + Time ago
- Row 2: Patient Name (age/gender) + Caller phone
- Row 3: Pickup -> Destination route
- Tags row: Condition chip + ICU chip + Pediatric chip
- Action row: [CALL VERIFY] [VIEW DETAILS] [SEND TO TEAM LEAD]

#### AgentShiftBanner

Left emerald accent border, surfaceContainerLow bg, Inter bodyMd for agent name/ID, labelSm for shift time/status.

#### BookingLifecycleTimeline

Vertical timeline nodes:
- Completed: emerald filled circle + label
- Active: primary outlined circle + animated pulse ring
- Upcoming: outline circle, muted text

#### VerificationChecklistView

Protocol checkboxes with secondary check icons for verified items, outlineVariant ring for unchecked. Progress summary: X/Y complete, secondary progress bar.

#### CallOutcomeSelector

Full-width radio group:
- Verified (secondary/emerald accent)
- Unable to Contact (warning/amber accent)
- Requires Escalation (error/red accent)
Each option has a title + descriptive sub-label.

#### TelemetryRadarCard

Air corridor radar-style animated widget. Tappable to navigate to 360 degree case details.

#### LiveGPSTelemetryDialog

Modal: last known GPS coordinates (JetBrains Mono), last ping timestamp, telemetry freshness dot (live/stale/unavailable), ambulance unit + driver name.

---

## 6. Cross-Portal Design Rules

| Rule | Detail |
|---|---|
| Booking ID format | Always in JetBrains Mono, uppercase, bold — never plain Inter |
| Urgency pip | Left-edge 4–5px colored bar on any booking card — CRITICAL=error, URGENT=warning, NORMAL=secondary |
| Status badges | Pill-shaped, semantic color per status — never plain text labels for operational states |
| Empty states | Always icon + heading + description — never a blank area or bare "no data" text |
| Loading states | LinearProgressIndicator (minHeight: 2) below header — non-blocking |
| Error banners | Full-width error strip below header with icon, message, Retry button |
| ETA display | Always in error color — urgency communication |
| Patient initials | CircleAvatar with primaryContainer bg, white text |
| Timestamps | Relative ("3m ago") for live feeds; absolute for audit/archive |
| Form buttons | Full-width at bottom of form screens |
| Material 3 | useMaterial3: true on all ThemeData, no legacy M2 overrides |

---

## 7. Semantic Color Usage Guide

| Situation | Color Token | Example |
|---|---|---|
| Live / Available / Verified | secondary (#006C4A) + secondaryContainer | Available driver badge, Verified case label |
| In Transit / Pending / Warning | warning (#D97706) + warningContainer | In-transit status, Pending calls KPI card |
| Critical / Code Red / Error | error (#DC2626) + errorContainer | Code Red badges, CRITICAL audit entry, ETA label |
| Primary Brand / CTA / Assignment | primaryContainer (#0369A1) | Buttons, active mission header, booking ID accents |
| Specialist / PICU / Pediatric | tertiary CC (#392CD1) | Pediatric chip, PICU protocol indicator |
| Muted / Timestamp / Secondary text | outline (#707881) | "3m ago", capacity labels, disclaimer text |
| Telemetry Live | liveTelemetry (#10B981) | GPS live ping dot (Driver HUD) |
| Telemetry Stale | staleTelemetry (#F59E0B) | GPS last-updated over 2 min (Driver HUD) |
| Telemetry Unavailable | unavailableTelemetry (#EF4444) | GPS offline indicator (Driver HUD) |

---

## 8. Accessibility & Responsiveness

### Color Contrast

- All primary text (onSurface #0B1C30) on background (#F8F9FF) — WCAG AA compliant (contrast ratio > 7:1)
- Error red on white: > 4.5:1 — AA compliant
- White text on primaryContainer (#0369A1) — AA compliant

### Responsive Layout

| Portal | Responsive Behavior |
|---|---|
| Admin | Web-first. KPI grid 2-column on standard web. Fleet/staff grids adapt to screen width. |
| Driver | Mobile-first. Padding symmetric(horizontal: 16). Cards full-width. |
| Customer Care | KPI grid: 2-column on narrow, 4-column on width > 580px (LayoutBuilder). Login max-width: 440px. |

### Touch Targets

- All tappable elements wrapped in InkWell with borderRadius matching container
- Minimum tap target: 44x44px for icon buttons
- Full-width form buttons use minimumSize: Size.fromHeight(44–48)

### Text Scalability

- height parameters set on all TextStyle definitions to ensure consistent line-height under system font scaling
- All numeric/telemetry displays use absolute JetBrains Mono sizes — not scaled by Dynamic Type, preserving HUD layout integrity

---

*This document reflects the design system as implemented in the codebase.*
*Key source files: lib/roles/admin/theme/admin_theme.dart, lib/features/driver/theme/, lib/features/customer_care/theme/*
*Stitch MCP Project references: DriverColors (Project 15205856723727982878), CustomerCareColors (Project 1449624092268908152)*
