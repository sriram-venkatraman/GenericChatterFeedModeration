trigger FeedItemTrigger on FeedItem (before insert, before update) {

    ModerationHandler mh = new ModerationHandler();
    Map<String, String> fiInMap = new Map<String, String>();
    Map<String, ModerationHandler.ModerationResponse> fiOutMap;
    
    FeedItem fi;
    for (Integer i = 0; i < Trigger.new.size(); i++) {
        fi = Trigger.new[i];
        if (!String.isEmpty(fi.Title)) {
            fiInMap.put(i.format()+'T', fi.Title);
        }
        fiInMap.put(i.format(), fi.Body);
    }
    
    if (fiInMap.size() > 0) {
        fiOutMap = mh.checkContent(fiInMap);
    }
    
    for (String k : fiOutMap.keySet()) {
        ModerationHandler.ModerationResponse mr = fiOutMap.get(k);

        Integer j;
        Boolean isTitle = false;
        if (k.endsWith('T')) {
            isTitle = true;
            j = Integer.valueOf(k.split('T')[0]);
        } else {
            j = Integer.valueOf(k);
        }
        if (mr.getStatus().startsWith('Error!')) {
            Trigger.new[j].Body.addError(mr.getStatus());
        }
        if (mr.getStatus().startsWith('Warning!')) {
            Trigger.new[j].Status = 'PendingReview';
        }
        if (mr.getStatus().startsWith('Redacted!')) {
            Trigger.new[j].Status = 'Published';
            String s = mr.getRedactedContent();
            if (isTitle) {
                Trigger.new[j].Title = s;
            } else {
                Trigger.new[j].Body = s;
            }
        }
        if (Trigger.isUpdate) {
            if (mr.getStatus() == 'OK' && Trigger.old[j].Status == 'PendingReview') {
                Trigger.new[j].Status = 'Published';
            }
        }
    }
    
}