P.1. DNA-PCR TEST [program: EARLY INFANT DIAGNOSIS PROGRAM, scope: RECENT, concept: DNA-PCR Testing Result]
C.1.1. Given an exposed, when the child is being enrolled:
Q.1.1.1. DNA-PCR Testing Sample Date [pos: 0, field_type: date, tt_onLoad: showCategory("DNA-PCR Test")]

Q.1.1.2. DNA-PCR Testing Sample ID [pos: 1]

Q.1.1.3. DNA-PCR Testing Result received Date [pos: 2, field_type: date]

Q.1.1.4. DNA-PCR Testing Result [pos: 3]
O.1.1.4.1. Negative
O.1.1.4.2. Positive

Q.1.1.5. DNA-PCR Testing Result given Date [pos: 4, field_type: date]

Q.1.1.6. DNA-PCR Testing Result given Age (months) [pos: 5, absoluteMax: <%= @patient.age_in_months + 1%>, concept: DNA-PCR Testing Result given Age, field_type: number, tt_pageStyleClass: NumbersOnlyWithUnknown]
