import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import saveOpportunity from '@salesforce/apex/OpportunityController.saveOpportunity';
import getOpportunityData from '@salesforce/apex/OpportunityController.getOpportunityData';
import sendApprovalEmail from '@salesforce/apex/OpportunityController.sendApprovalEmail';
import markScreeningCompleted from '@salesforce/apex/OpportunityController.markScreeningCompleted';
import markScreeningSubmit from '@salesforce/apex/OpportunityController.markScreeningSubmit';

export default class ModalPop extends LightningElement {
    @api recordId;
    @track isModalOpen = true;
    @track isSecondScreenOpen = false;
    @track isThirdScreenOpen = false;
    @track answeredCount = 0;
    @track notAnsweredCount = 0;
    @track achievedScore = 0;
    @track probabilityValue = 0;
    @track currentStepValue = 'step1';  // step1, step2, or step3
    @track originalData = {};
    @track isConfirmModalOpen = false;   // NEW
    @track pendingSubmitAction = null;   // stores the callback for the real submit
    @track popupCloseFromCancel=true;
       get anyModalOpen() {
     this.isConfirmModalOpen;
}
    @track b1Questions = [
        { id: 1, displayId: 1, question: 'Project Name', field: 'B1_Q1__c', answer: false, commentField: 'B1_Q1_Comment__c', comment: '', isCommentDisabled: true, score: 0, isCombobox: false ,commentErrorClass: ''},
        { id: 2, displayId: 2, question: 'End User Details', field: 'B1_Q2__c', answer: false, commentField: 'B1_Q2_Comment__c', comment: '', isCommentDisabled: true, score: 0, isCombobox: false ,commentErrorClass: ''},
        { id: 3, displayId: 3, question: 'Submission Deadline', field: 'B1_Q3__c', answer: false, commentField: 'B1_Q3_Comment__c', comment: '', isCommentDisabled: true, score: 0, isCombobox: false ,commentErrorClass: ''},
        { id: 4, displayId: 4, question: 'Project Award Date', field: 'B1_Q4__c', answer: false, commentField: 'B1_Q4_Comment__c', comment: '', isCommentDisabled: true, score: 0, isCombobox: false ,commentErrorClass: ''},
        { id: 5, displayId: 5, question: 'If Won – how much time to release the PO', field: 'B1_Q5__c', answer: false, commentField: 'B1_Q5_Comment__c', comment: '', isCommentDisabled: true, score: 0, isCombobox: false ,commentErrorClass: ''},
        { id: 6, displayId: 6, question: 'Is this a public tender OR opportunity currently on hand?', field: 'B1_Q6__c', answer: false, commentField: 'B1_Q6_Comment__c', comment: '', isCommentDisabled: true, score: 0, isCombobox: false ,commentErrorClass: ''},
        { id: 7, displayId: 7, question: 'Has your company worked with this EU before? If Yes, for how many years?', field: 'B1_Q7__c', answer: false, commentField: 'B1_Q7_Comment__c', comment: '', isCommentDisabled: true, score: 0, isCombobox: false,commentErrorClass: '' },
        { id: 8, displayId: 8, question: 'In your opinion, what are your chances of winning in the quarter – 25%, 50%, 75%, 100%', field: 'B1_Q8__c', answer: false, commentField: 'B1_Q8_Comment__c', comment: '', isCommentDisabled: true, score: 0, isCombobox: true ,commentErrorClass: ''},
        { id: 9, displayId: 9, question: 'Do you believe this EU will award to the lowest price product OR is the EU looking for a solution which is high quality, secure, rugged and has references of large scale deployment globally', field: 'B1_Q9__c', answer: false, commentField: 'B1_Q9_Comment__c', comment: '', isCommentDisabled: true, score: 0, isCombobox: false ,commentErrorClass: ''},
        { id: 10, displayId: 10, question: 'Does it matter to the EU if the product is made in Canada/North America', field: 'B1_Q10__c', answer: false, commentField: 'B1_Q10_Comment__c', comment: '', isCommentDisabled: true, score: 0, isCombobox: false ,commentErrorClass: ''}
    ];

    @track b2Questions = [
        { id: 1, displayId: 11, question: 'Is it an existing installation or a fresh installation? ', field: 'B2_Q1__c', answer: false, commentField: 'B2_Q1_Comment__c', comment: '', isCommentDisabled: true, score: 0, isCombobox: false ,commentErrorClass: ''},
        { id: 2, displayId: 12, question: 'How many total devices required for the project?', field: 'B2_Q2__c', answer: false, commentField: 'B2_Q2_Comment__c', comment: '', isCommentDisabled: true, score: 0, isCombobox: false ,commentErrorClass: ''},
        { id: 3, displayId: 13, question: 'Enterprise Series / TFACE / TITAN / MYCRO', field: 'B2_Q3__c', answer: false, commentField: 'B2_Q3_Comment__c', comment: '', isCommentDisabled: true, score: 0, isCombobox: true ,commentErrorClass: ''},
        { id: 4, displayId: 14, question: 'Does the customer require support for RFID Cards? Please specify the preferred Card Technology (e.g., Mifare, Em Prox, iClass, etc.)', field: 'B2_Q4__c', answer: false, commentField: 'B2_Q4_Comment__c', comment: '', isCommentDisabled: true, score: 0, isCombobox: false ,commentErrorClass: ''},
        { id: 5, displayId: 15, question: 'What is the application? Is it for access control, Time & Attendance, VMS, or all? ', field: 'B2_Q5__c', answer: false, commentField: 'B2_Q5_Comment__c', comment: '', isCommentDisabled: true, score: 0, isCombobox: false ,commentErrorClass: ''},
        { id: 6, displayId: 16, question: 'Is there any requirement document outlining the required features and functionalities? ', field: 'B2_Q6__c', answer: false, commentField: 'B2_Q6_Comment__c', comment: '', isCommentDisabled: true, score: 0, isCombobox: false ,commentErrorClass: ''},
        { id: 7, displayId: 17, question: 'Is a Visitor Management system required?', field: 'B2_Q7__c', answer: false, commentField: 'B2_Q7_Comment__c', comment: '', isCommentDisabled: true, score: 0, isCombobox: false ,commentErrorClass: ''},
        { id: 8, displayId: 18, question: 'Which of the following features should the proposed devices support? (Face Recognition + Fingerprint/ Dynamic QR Code/ Fingerprint Only, etc.)', field: 'B2_Q8__c', answer: false, commentField: 'B2_Q8_Comment__c', comment: '', isCommentDisabled: true, score: 0, isCombobox: false ,commentErrorClass: ''},
        { id: 9, displayId: 19, question: 'Are there any integrations with third party systems (Access Control, HRMS, or VMS) required? Please provide the name of the provider, software name, and version', field: 'B2_Q9__c', answer: false, commentField: 'B2_Q9_Comment__c', comment: '', isCommentDisabled: true, score: 0, isCombobox: false ,commentErrorClass: ''},
        { id: 10, displayId: 20, question: 'Where will the devices be installed, in an indoor or outdoor environment? Specify the quantity for each', field: 'B2_Q10__c', answer: false, commentField: 'B2_Q10_Comment__c', comment: '', isCommentDisabled: true, score: 0, isCombobox: false ,commentErrorClass: ''},
        { id: 11, displayId: 21, question: 'What are the preferred connectivity options? Ethernet, Wi-Fi, or 4G Cellular? ', field: 'B2_Q11__c', answer: false, commentField: 'B2_Q11_Comment__c', comment: '', isCommentDisabled: true, score: 0, isCombobox: false ,commentErrorClass: ''}
    ];

    @track b3Questions = [
        { id: 1, displayId: 22, question: 'If EU has adequate budget', field: 'B3_Q1__c', answer: false, commentField: 'B3_Q1_Comment__c', comment: '', isCommentDisabled: true, score: 0, isCombobox: false,commentErrorClass: '' },
        { id: 2, displayId: 23, question: 'Is there a mandatory completion date for a project?', field: 'B3_Q2__c', answer: false, commentField: 'B3_Q2_Comment__c', comment: '', isCommentDisabled: true, score: 0, isCombobox: false ,commentErrorClass: ''},
        { id: 3, displayId: 24, question: 'Who are the decision makers in the project? (CEO/ Project Team/ Other)', field: 'B3_Q3__c', answer: false, commentField: 'B3_Q3_Comment__c', comment: '', isCommentDisabled: true, score: 0, isCombobox: false ,commentErrorClass: ''},
        { id: 4, displayId: 25, question: 'Customization required?', field: 'B3_Q4__c', answer: false, commentField: 'B3_Q4_Comment__c', comment: '', isCommentDisabled: true, score: 0, isCombobox: false,commentErrorClass: '' },
        { id: 5, displayId: 26, question: 'If on-site demo or PoC is required?', field: 'B3_Q5__c', answer: false, commentField: 'B3_Q5_Comment__c', comment: '', isCommentDisabled: true, score: 0, isCombobox: false ,commentErrorClass: ''}
    ];
    @track hasUserMadeChanges = false;  // ← ADD THIS

    // Options for B1_Q8_Comment__c (percentage dropdown)
    chancesOptions = [
        { label: '25%', value: '25%' },
        { label: '50%', value: '50%' },
        { label: '75%', value: '75%' },
        { label: '100%', value: '100%' }
    ];

    // Options for Q13 (Enterprise Series / TFACE / TITAN / MYCRO)
    productOptions = [
        { label: 'Enterprise Series', value: 'Enterprise Series' },
        { label: 'TFACE', value: 'TFACE' },
        { label: 'TITAN', value: 'TITAN' },
        { label: 'MYCRO', value: 'MYCRO' }
    ];

    // Weights for scoring
    weights = {
        'B1_Q1__c': 1,
        'B1_Q2__c': 2,
        'B1_Q3__c': 2,
        'B1_Q4__c': 3,
        'B1_Q5__c': 3,
        'B1_Q6__c': 2,
        'B1_Q7__c': 1,
        'B1_Q8__c': 3,
        'B1_Q9__c': 2,
        'B1_Q10__c': 2,
        'B2_Q1__c': 1,
        'B2_Q2__c': 3,
        'B2_Q3__c': 3,
        'B2_Q4__c': 1,
        'B2_Q5__c': 2,
        'B2_Q6__c': 2,
        'B2_Q7__c': 1,
        'B2_Q8__c': 1,
        'B2_Q9__c': 2,
        'B2_Q10__c': 1,
        'B2_Q11__c': 1,
        'B3_Q1__c': 2,
        'B3_Q2__c': 2,
        'B3_Q3__c': 2,
        'B3_Q4__c': 3,
        'B3_Q5__c': 2
    };

    // Handle progress step click
    handleStepClick(event) {
        event.preventDefault();
        const stepValue = event.target.value;
        this.currentStepValue = stepValue;

        // Update screen visibility based on step
        if (stepValue === 'step1') {
            this.isSecondScreenOpen = false;
            this.isThirdScreenOpen = false;
        } else if (stepValue === 'step2') {
            this.isSecondScreenOpen = true;
            this.isThirdScreenOpen = false;
        } else if (stepValue === 'step3') {
            this.isSecondScreenOpen = false;
            this.isThirdScreenOpen = true;
        }
    }

    // Load existing opportunity data
    connectedCallback() {
        if (window.location.href.includes('flexipageEditor')) {
            console.log('Running inside App Builder, suppressing modal');
            this.isModalOpen = false;
            return;
        }

        this.isModalOpen = true;
        if (this.recordId) {
            getOpportunityData({ opportunityId: this.recordId })
                .then(data => {
                    // === STORE ORIGINAL DATA ===
                    this.originalData = { ...data }
                    // Update B1 Questions
                    this.b1Questions = this.b1Questions.map(q => {
                        const answer = data[q.field] === 'Yes';
                        const score = answer ? (q.isCombobox ? (data[q.commentField] === '25%' ? 0 : data[q.commentField] === '50%' ? 1 : data[q.commentField] === '75%' ? 2 : data[q.commentField] === '100%' ? 3 : 0) : this.weights[q.field]) : 0;
                        return {
                            ...q,
                            answer,
                            comment: data[q.commentField] || '',
                            isCommentDisabled: !answer,
                            score
                        };
                    });

                    // Update B2 Questions
                    this.b2Questions = this.b2Questions.map(q => {
                        const answer = data[q.field] === 'Yes';
                        let score = 0;
                        if (answer) {
                            if (q.isCombobox) {
                                score = this.getProductScore(data[q.commentField]);
                            } else {
                                score = this.weights[q.field];
                            }
                        }
                        return {
                            ...q, answer,
                            comment: data[q.commentField] || '',
                            isCommentDisabled: !answer,
                            score
                        };
                    });

                    // Update B3 Questions
                    this.b3Questions = this.b3Questions.map(q => {
                        const answer = data[q.field] === 'Yes';
                        return {
                            ...q,
                            answer,
                            comment: data[q.commentField] || '',
                            isCommentDisabled: !answer,
                            score: answer ? this.weights[q.field] : 0
                        };
                    });

                    this.probabilityValue = data['Probability__c'] || 0;
                    this.recalculateSummary();
                })
                .catch(error => {
                    console.error('Error loading opportunity data:', error);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Failed to load opportunity data.',
                            variant: 'error'
                        })
                    );
                });
        }
    }

    // Getters for summary calculations
    get totalQuestions() {
        return this.b1Questions.length + this.b2Questions.length + this.b3Questions.length;
    }

    get answeredCount() {
        const b1Answered = this.b1Questions.filter(q => q.answer).length;
        const b2Answered = this.b2Questions.filter(q => q.answer).length;
        const b3Answered = this.b3Questions.filter(q => q.answer).length;
        return b1Answered + b2Answered + b3Answered;
    }

    get notAnsweredCount() {
        return this.totalQuestions - this.answeredCount;
    }

    get achievedScore() {
        const b1Scores = this.b1Questions.reduce((sum, q) => sum + (q.score || 0), 0);
        const b2Scores = this.b2Questions.reduce((sum, q) => sum + (q.score || 0), 0);
        const b3Scores = this.b3Questions.reduce((sum, q) => sum + (q.score || 0), 0);
        return b1Scores + b2Scores + b3Scores;
    }

    get probability() {
        const totalWeight = Object.values(this.weights).reduce((sum, weight) => sum + (weight || 0), 0);
        this.probabilityValue = totalWeight > 0 ? Number(((this.achievedScore / totalWeight) * 100).toFixed(0)) : 0;
        return this.probabilityValue;
    }

    get probabilityClass() {
        const probability = parseFloat(this.probability);
        const chance = parseFloat(this.b1Questions.find(q => q.field === 'B1_Q8__c')?.comment.replace('%', '') || 0);
        if (probability < 70 && probability !== 0) {
            return 'probability-red';
        } else if (probability >= 70 && chance < 75 && probability !== 0) {
            return 'probability-orange';
        } else if (probability >= 70 && chance > 74 && probability !== 0) {
            return 'probability-green';
        }
        return '';
    }

    get probabilityCellClass() {
        const f6 = this.probability;
        const q8 = this.b1Questions.find(q => q.field === 'B1_Q8__c');
        const e19 = q8 ? parseFloat(q8.comment?.replace('%', '') || 0) : 0;

        const isRed = (f6 < 70 && f6 !== 0) && (e19 < 75 || true);
        const isOrange = f6 >= 70 && e19 < 75 && f6 !== 0;
        const isGreen = f6 >= 70 && e19 > 74 && f6 !== 0;

        let colourClass = '';
        if (isRed) colourClass = 'probability-red';
        else if (isOrange) colourClass = 'probability-orange';
        else if (isGreen) colourClass = 'probability-green';

        return `summary-box probability-value ${colourClass}`;
    }
    getScoreFromChance(value) {
        return value === '25%' ? 0 : value === '50%' ? 1 : value === '75%' ? 2 : value === '100%' ? 3 : 0;
    }
    getProductScore(value) {
        const map = {
            'Enterprise Series': 1,
            'TFACE': 2,
            'TITAN': 3,
            'MYCRO': 1
        };
        return map[value] ?? 0;
    }
    setCommentErrorClass(questionsArray) {
    return questionsArray.map(q => {
        const hasError = q.answer && (!q.comment || q.comment.trim() === '');
        return {
            ...q,
            commentErrorClass: hasError ? 'invalid_field' : ''
        };
    });
}
    // Handle checkbox changes for first screen
    handleCheckboxChange(event) {
        const field = event.target.dataset.field;
        const isChecked = event.detail.checked;
        const originalAnswer = this.originalData[field] === 'Yes';

        if (originalAnswer !== isChecked) {
            this.hasUserMadeChanges = true;
        }
        this.b1Questions = this.b1Questions.map(q => {
            if (q.field === field) {
                let score = 0;
                if (isChecked) {
                    score = q.isCombobox ? (q.comment === '25%' ? 0 : q.comment === '50%' ? 1 : q.comment === '75%' ? 2 : q.comment === '100%' ? 3 : 0) : this.weights[field];
                }
                return { ...q, answer: isChecked, isCommentDisabled: !isChecked, score, comment: isChecked ? q.comment : '' };
            }
            return q;
        });
        this.recalculateSummary();
    }

    // Handle comment changes for first screen
    handleCommentChange(event) {
        const field = event.target.dataset.field;
        const value = event.detail.value;
        const question = this.b1Questions.find(q => q.commentField === field);
        const originalComment = this.originalData[question.commentField] || '';

        if (originalComment !== value) {
            this.hasUserMadeChanges = true;
        }
        this.b1Questions = this.b1Questions.map(q => {
            if (q.commentField === field) {
                const score = q.isCombobox && q.answer ? (value === '25%' ? 0 : value === '50%' ? 1 : value === '75%' ? 2 : value === '100%' ? 3 : 0) : q.score;
                return { ...q, comment: value, score ,
                commentErrorClass: q.answer && (!value || value.trim() === '') ? 'invalid_field' : ''};
            }
            return q;
        });
        this.recalculateSummary();
    }

    // Handle checkbox changes for second screen
    handleSecondScreenCheckboxChange(event) {
        const field = event.target.dataset.field;
        const checked = event.detail.checked;
        const originalAnswer = this.originalData[field] === 'Yes';

        if (originalAnswer !== checked) {
            this.hasUserMadeChanges = true;
        }
        this.b2Questions = this.b2Questions.map(q => {
            if (q.field !== field) return q;

            let score = 0;
            if (checked) {
                if (q.isCombobox) {
                    score = this.getProductScore(q.comment);
                } else {
                    score = this.weights[field];
                }
            }
            return {
                ...q, answer: checked,
                isCommentDisabled: !checked,
                score,
                comment: checked ? q.comment : ''
            };
        });
        this.recalculateSummary();
    }

    // Handle comment changes for second screen
handleSecondScreenCommentChange(event) {
    const field = event.target.dataset.field;
    const value = event.detail.value;

    const question = this.b2Questions.find(q => q.commentField === field);
    if (!question) {
        console.warn('No question found for commentField:', field);
        return;
    }

    const originalComment = this.originalData[question.commentField] || '';
    if (originalComment !== value) {
        this.hasUserMadeChanges = true;
    }

    this.b2Questions = this.b2Questions.map(q => {
        if (q.commentField !== field) return q;

        // CORRECTED LOGIC:
        const score = q.answer 
            ? (q.isCombobox 
                ? this.getProductScore(value) 
                : this.weights[q.field])  // Use weight for textarea
            : 0;

        return { ...q, comment: value, score };
    });

    this.recalculateSummary();
}

    // Handle checkbox changes for third screen
    handleThirdScreenCheckboxChange(event) {
        const field = event.target.dataset.field;
        const isChecked = event.detail.checked;
        const originalAnswer = this.originalData[field] === 'Yes';

        if (originalAnswer !== isChecked) {
            this.hasUserMadeChanges = true;
        }
        this.b3Questions = this.b3Questions.map(q => {
            if (q.field === field) {
                const score = isChecked ? this.weights[field] : 0;
                return { ...q, answer: isChecked, isCommentDisabled: !isChecked, score, comment: isChecked ? q.comment : '' };
            }
            return q;
        });
        this.recalculateSummary();
    }

    // Handle comment changes for third screen
    handleThirdScreenCommentChange(event) {
        const field = event.target.dataset.field;
        const value = event.detail.value;

        // FIX: Search in b3Questions
        const question = this.b3Questions.find(q => q.commentField === field);

        if (!question) {
            console.warn('No question found for commentField:', field);
            return;
        }

        const originalComment = this.originalData[question.commentField] || '';

        if (originalComment !== value) {
            this.hasUserMadeChanges = true;
        }

        this.b3Questions = this.b3Questions.map(q => {
            if (q.commentField === field) {
                return { ...q, comment: value };
            }
            return q;
        });

        this.recalculateSummary();
    }
    hasMissingComments(questions) {
        return questions.some(q => q.answer && (!q.comment || q.comment.trim() === ''));
    }
    validateAndShowError(questions, errorMsg) {
        if (this.hasMissingComments(questions)) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Validation Error',
                    message: errorMsg,
                    variant: 'error'
                })
            );
            return false;
        }
        return true;
    }

    // Navigation and save handlers
    // saveAndClose() {
    //     this.saveData(false, true, () => {
    //         //if (this.probabilityClass === 'probability-green' && this.hasUserMadeChanges) {
    //         if (this.probabilityClass === 'probability-green') {
    //             this.sendEmailAndClose();
    //         } else {
    //             this.closeModal();
    //         }
    //     });
    // }
    saveAndContinue() {
        this.b1Questions = this.setCommentErrorClass(this.b1Questions);

    if (this.hasMissingComments(this.b1Questions)) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Validation Error',
            message: 'Please fill the comment for every checked question.',
            variant: 'error'
        }));
        return;
    }

    // Clear errors on success
    this.b1Questions = this.b1Questions.map(q => ({ ...q, commentErrorClass: '' }));
        this.saveData(true);
        this.currentStepValue = 'step2';  // Move to Technical Knowledge
    }

    goToThirdScreen() {
        this.b2Questions = this.setCommentErrorClass(this.b2Questions);

    if (this.hasMissingComments(this.b2Questions)) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Validation Error',
            message: 'Please fill the comment for every checked question.',
            variant: 'error'
        }));
        return;
    }

    this.b2Questions = this.b2Questions.map(q => ({ ...q, commentErrorClass: '' }));
        this.saveData(true, false, () => {
            this.isSecondScreenOpen = false;
            this.isThirdScreenOpen = true;
            this.currentStepValue = 'step3';  // Move to Project Details
        });
    }

    backToFirstScreen() {
        this.isSecondScreenOpen = false;
        this.isThirdScreenOpen = false;
        this.currentStepValue = 'step1';  // Back to SI Alignment
    }

    backToSecondScreen() {
        this.isSecondScreenOpen = true;
        this.isThirdScreenOpen = false;
        this.currentStepValue = 'step2';  // Back to Technical Knowledge
    }

    submitAndClose() {
    this.handleSubmitClick();
    }
    reloadRecordPage() {
        window.location.reload();   // Full page reload – exactly what you asked for
    }

    closeModal() {
        this.handleCancel();
        this.isModalOpen = false;
        this.dispatchEvent(new CustomEvent('closemodal'));
        this.reloadRecordPage();   // RELOAD PAGE
    }

    saveData(continueToNextScreen, isSubmit = false, callback = null) {
        this.recalculateSummary();
        const opportunityData = {
            Id: this.recordId,
            ...this.b1Questions.reduce((acc, q) => ({
                ...acc,
                [q.field]: q.answer ? 'Yes' : 'No',
                [q.commentField]: q.comment,
                [`${q.field.replace('__c', '_Score__c')}`]: q.score
            }), {}),
            ...this.b2Questions.reduce((acc, q) => ({
                ...acc,
                [q.field]: q.answer ? 'Yes' : 'No',
                [q.commentField]: q.comment,
                [`${q.field.replace('__c', '_Score__c')}`]: q.score
            }), {}),
            ...this.b3Questions.reduce((acc, q) => ({
                ...acc,
                [q.field]: q.answer ? 'Yes' : 'No',
                [q.commentField]: q.comment,
                [`${q.field.replace('__c', '_Score__c')}`]: q.score
            }), {}),
            // ---- NEW SUMMARY FIELDS ----
            Answered__c: this.answeredCount,
            Not_Answered__c: this.notAnsweredCount,
            Achieved_Score__c: this.achievedScore,
            Probability__c: this.probabilityValue
        };

        saveOpportunity({ opportunityData })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: isSubmit ? 'Opportunity submitted successfully!' : 'Opportunity saved successfully!',
                        variant: 'success'
                    })
                );
                if (callback) {
                    callback();
                } else if (continueToNextScreen) {
                    this.isSecondScreenOpen = true;
                    this.isThirdScreenOpen = false;
                }
            })
            .catch(error => {
                console.error('Error saving opportunity:', error);
                console.error('Error saving opportunity:', {
                    message: error.body?.message || error.message,
                    exceptionType: error.body?.exceptionType,
                    stackTrace: error.body?.stackTrace,
                    errorCode: error.body?.errorCode,
                    fullError: error
                });
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Failed to save opportunity.',
                        variant: 'error'
                    })
                );
            });
    }

    recalculateSummary() {
        // ----- answered / not answered -----
        const b1Ans = this.b1Questions.filter(q => q.answer).length;
        const b2Ans = this.b2Questions.filter(q => q.answer).length;
        const b3Ans = this.b3Questions.filter(q => q.answer).length;

        this.answeredCount = b1Ans + b2Ans + b3Ans;
        this.notAnsweredCount = this.totalQuestions - this.answeredCount;

        // ----- achieved score -----
        const b1Score = this.b1Questions.reduce((s, q) => s + (q.score || 0), 0);
        const b2Score = this.b2Questions.reduce((s, q) => s + (q.score || 0), 0);
        const b3Score = this.b3Questions.reduce((s, q) => s + (q.score || 0), 0);
        this.achievedScore = b1Score + b2Score + b3Score;

        // ----- probability -----
        const totalWeight = Object.values(this.weights).reduce((s, w) => s + w, 0);
        this.probabilityValue = totalWeight > 0
            ? Math.round((this.achievedScore / totalWeight) * 100)
            : 0;
    }

    sendEmailAndClose() {
        
        sendApprovalEmail({
            oppId: this.recordId,
            targetEmail: 'simran.nandla@getoncrm.com'
        })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Email sent!',
                        variant: 'success'
                    })
                );
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body?.message || 'Failed to send email.',
                        variant: 'error'
                    })
                );
            })
            .finally(() => {
                this.popupCloseFromCancel=false;
                this.closeModal();  // Always close after email attempt
            });
    }
    handleCancel() {
        markScreeningCompleted({ opportunityId: this.recordId ,fromCancel:this.popupCloseFromCancel})
            .then(() => {
                // this.dispatchEvent(
                //     new ShowToastEvent({
                //         title: 'Cancelled',
                //         message: 'Screening has been marked as completed.',
                //         variant: 'info'
                //     })
                // );
            })
            .catch(error => {
                console.error('Cancel error:', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body?.message || 'Could not complete cancellation.',
                        variant: 'error'
                    })
                );
            })
    }
    /* --------------------------------------------------------------------- */
    /*  NEW: Submit button handler – decides whether to show confirm modal  */
    /* --------------------------------------------------------------------- */
    handleSubmitClick() {
        // Run the same validation you already have
        this.b3Questions = this.setCommentErrorClass(this.b3Questions);
        if (this.hasMissingComments(this.b3Questions)) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Validation Error',
                message: 'Please fill the comment for every checked question.',
                variant: 'error'
            }));
            return;
        }
        this.b3Questions = this.b3Questions.map(q => ({ ...q, commentErrorClass: '' }));

        // ---- RED PROBABILITY CHECK ----
        if (this.probabilityCellClass.includes('probability-red')) {
            this.openConfirmModal(() => this.performFinalSubmit());
        } else {
            this.performFinalSubmit();
        }
    }

    /* ---------------------------------------------------- */
    /*  Open the small confirmation modal & store callback */
    /* ---------------------------------------------------- */
    openConfirmModal(callback) {
        this.pendingSubmitAction = callback;
        this.isConfirmModalOpen = true;
    }
 
    /* -------------------------- */
    /*  OK → run stored callback */
    /* -------------------------- */
    confirmSubmit() {
        this.isConfirmModalOpen = false;
        if (this.pendingSubmitAction) {
            this.pendingSubmitAction();
            this.pendingSubmitAction = null;
        }
    }

    /* ------------------------------------- */
    /*  Cancel → only close the confirm modal */
    /* ------------------------------------- */
    cancelConfirm() {
        this.isConfirmModalOpen = false;
        this.pendingSubmitAction = null;
    }

    /* ----------------------------------------------------------- */
    /*  The original submit logic (mark, save, email, close)      */
    /* ----------------------------------------------------------- */
    performFinalSubmit() {
        markScreeningSubmit({ opportunityId: this.recordId })
            .then(() => { /* silent */ })
            .catch(err => this.showErrorToast(err));

        this.saveData(false, true, () => {
            if (this.probabilityClass === 'probability-green') {
                this.sendEmailAndClose();
            } else {
                this.popupCloseFromCancel=false;
                this.closeModal();
            }
        });
    }

    /* ----------------------------------------------------------------- */
    /*  Helper – tiny wrapper for toast errors (keeps code DRY)          */
    /* ----------------------------------------------------------------- */
    showErrorToast(error) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: error.body?.message || 'An unexpected error occurred.',
            variant: 'error'
        }));
    }
    stopPropagation(event) {
    event.stopPropagation();
}
}