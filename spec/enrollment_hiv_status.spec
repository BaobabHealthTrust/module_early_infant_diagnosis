P.1. HIV STATUS AT ENROLLMENT [program: EARLY INFANT DIAGNOSIS PROGRAM, label: Enrollment Status, scope: RECENT, concept: Mother HIV Status]
C.1.1. Given an exposed child under 24 months, collect the following details on enrollment:
Q.1.1.1. Age of child (months) [concept: Age of child, value: <%= @patient.age_in_months %>, field_type: number, tt_pageStyleClass: NumbersOnlyWithUnknown, pos: 0]
Q.1.1.2. Rapid Antibody Testing Result [pos: 1]
O.1.1.2.1. Not Done
O.1.1.2.2. Negative
O.1.1.2.3. Positive
O.1.1.2.4. Inconclusive

Q.1.1.3. Rapid Antibody Testing Age (months) [concept: Rapid Antibody Testing Age, absoluteMax: <%= @patient.age_in_months%>, field_type: number, tt_pageStyleClass: NumbersOnlyWithUnknown, pos: 2]

Q.1.1.4. DNA-PCR Testing Result [pos: 3]
O.1.1.4.1. Not done
O.1.1.4.2. Negative
O.1.1.4.3. Positive

Q.1.1.5. DNA-PCR Testing Age (months) [concept: DNA-PCR Testing Result given Age, absoluteMax: <%= @patient.age_in_months%>, field_type: number, tt_pageStyleClass: NumbersOnlyWithUnknown, pos: 4]

Q.1.1.6. Confirmatory HIV test [pos: 5, tt_onLoad: setHIVStatusCheck("1.1.4"), tt_onUnLoad: unSetHIVStatus(), onchange: setHIVStatusCheck("1.1.4")]
O.1.1.6.1. Not confirmed
O.1.1.6.2. Confirmed

Q.1.1.7. Mother HIV Status [pos: 6]
O.1.1.7.1. Alive not on ART
O.1.1.7.2. Alive On ART
Q.1.1.7.2.1. Mother ART registration number
O.1.1.7.3. Died
O.1.1.7.4. Unknown

Q.1.1.8. Mother ART Registration Number [pos: 7, concept: Mother ART registration number, field_type: number, condition: __$("1.1.7").value.toLowerCase().match(/alive/i)]

