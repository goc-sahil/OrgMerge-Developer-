import { LightningElement, api, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';

import getOppRecord from '@salesforce/apex/OpportunityUpdateHelper.getOppRecord';
import updateStage from '@salesforce/apex/OpportunityUpdateHelper.updateStage';

export default class UpdateAndRefreshOpp extends LightningElement {
    @api recordId;
    @track oppData;
    wiredOppResult;

    @wire(getOppRecord, { recordId: '$recordId' })
    wiredOpp(result) {
        this.wiredOppResult = result;
        if(result.data) {
            this.oppData = result.data;
        }
    }

    handleUpdate() {
        updateStage({ recordId: this.recordId, stage: 'Closed Won' })
        .then(() => {
            // Refresh the LWC Data
            refreshApex(this.wiredOppResult);

            // Refresh the Record Page UI (Path, Highlights, Fields)
            notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
        });
    }
}
