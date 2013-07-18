P.1. RAPID ANTIBODY TEST [program: EARLY INFANT DIAGNOSIS PROGRAM, scope: RECENT, concept: Rapid Antibody Testing Sample Date]
C.1.1. Given an exposed child under 24 months, when the child is being enrolled:

Q.1.1.1. Rapid Antibody Testing Sample Date [tt_onLoad: showCategory("Rapid Antibody Test"), helpText: Date of Rapid Antibody Test Sample, pos: 0, field_type: date]

Q.1.1.2. Rapid Antibody Testing Age (months) [helpText: Age at Rapid Antibody Test Sample, pos: 1, absoluteMax: <%= @patient.age_in_months%>, concept: Rapid Antibody Testing Age, field_type: number, tt_pageStyleClass: NumbersOnlyWithUnknown]

Q.1.1.3. Rapid Antibody Testing HTC Serial No [pos: 2]

Q.1.1.4. Rapid Antibody Testing Result [pos: 3]
O.1.1.4.1. Negative
O.1.1.4.2. Positive
O.1.1.4.3. Inconclusive