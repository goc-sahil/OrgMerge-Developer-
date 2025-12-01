public class DerivedPricingCreator {
    @AuraEnabled
    public static void createDerivedPricingRecords(Id productId, Id contributingProductId) {
        // Step 1️⃣ — Fixed values
        String formula = 'TotalPrice * 0.18';
        String derivedPricingScope = 'Transactional';
        String pricingSource = 'Product';
        Datetime effectiveFrom = Datetime.valueOfGmt('2025-10-01 10:33:00');

        // Step 2️⃣ — List of Pricebook IDs
        List<Id> pricebookIds = new List<Id>{
            '01sbZ0000012JSbQAM',
			'01sbZ0000012JScQAM',
			'01sbZ0000012JSdQAM',
			'01sbZ0000012JSeQAM',
			'01sbZ0000012JSfQAM',
			'01sbZ0000012JSgQAM',
			'01sbZ0000012JShQAM',
			'01sbZ0000012JSiQAM',
			'01sbZ0000012JSjQAM',
			'01sbZ0000012JSkQAM',
			'01sbZ0000012JSlQAM',
			'01sbZ0000012JSmQAM',
			'01sbZ0000012JSnQAM',
			'01sbZ0000012JSoQAM',
			'01sbZ0000012JSpQAM',
			'01sbZ0000012JSqQAM',
			'01sbZ0000012JSrQAM',
			'01sbZ0000012JSsQAM',
			'01sbZ0000012JStQAM',
			'01sbZ0000012JSuQAM',
			'01sbZ0000012JSvQAM',
			'01sbZ0000012JSwQAM',
			'01sbZ0000012JSxQAM',
			'01sbZ0000012JSyQAM',
			'01sbZ0000012JSzQAM',
			'01sbZ0000012JT0QAM',
			'01sbZ0000012JT1QAM',
			'01sbZ0000012JT2QAM',
			'01sbZ0000012JT3QAM',
			'01sbZ0000012TJtQAM',
			'01s15000001p5jcAAA'

        };

        // Step 3️⃣ — Query all matching PricebookEntries for this product and Pricebooks
        List<PricebookEntry> pbEntries = [
            SELECT Id, Pricebook2Id, CurrencyIsoCode, Product2Id
            FROM PricebookEntry
            WHERE Product2Id = :productId
            AND Pricebook2Id IN :pricebookIds
        ];

        if (pbEntries.isEmpty()) {
            System.debug('⚠️ No PricebookEntry records found for this product in the given Pricebooks.');
            return;
        }

        // Step 4️⃣ — Fetch existing derived prices to prevent duplicates
        Set<String> existingCombinations = new Set<String>();

        for (PriceBookEntryDerivedPrice existing : [
            SELECT PricebookEntryId, ContributingProductId 
            FROM PriceBookEntryDerivedPrice 
            WHERE PricebookEntryId IN :pbEntries
        ]) {
            // Create a unique key per combination
            existingCombinations.add(existing.PricebookEntryId + '-' + existing.ContributingProductId);
        }

        // Step 5️⃣ — Build new derived pricing records
        List<PriceBookEntryDerivedPrice> recordsToInsert = new List<PriceBookEntryDerivedPrice>();
        for (PricebookEntry pbe : pbEntries) {
            String key = pbe.Id + '-' + contributingProductId;
            if (existingCombinations.contains(key)) {
                System.debug('⚠️ Skipping duplicate for PricebookEntryId ' + pbe.Id + ' and ContributingProductId ' + contributingProductId);
                continue;
            }

            recordsToInsert.add(new PriceBookEntryDerivedPrice(
                CurrencyIsoCode = pbe.CurrencyIsoCode,
                ContributingProductId = contributingProductId,
                PricebookEntryId = pbe.Id,
                DerivedPricingScope = derivedPricingScope,
                EffectiveFrom = effectiveFrom,
                Formula = formula,
                PricingSource = pricingSource,
                PricebookId = pbe.Pricebook2Id
            ));
        }

        // Step 6️⃣ — Insert all new records
        if (!recordsToInsert.isEmpty()) {
            insert recordsToInsert;
            System.debug('✅ Successfully inserted ' + recordsToInsert.size() + ' PriceBookEntryDerivedPrice records.');
        } else {
            System.debug('⚠️ No new records to insert (all already exist).');
        }
    }
}