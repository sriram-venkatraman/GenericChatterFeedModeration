trigger FeedItemTrigger on FeedItem (before insert, before update) {

    ModerationHandler mh = new ModerationHandler();
    Map<String, String> fiInMap = new Map<String, String>();
    Map<String, String> fiOutMap = new Map<String, String>();
    
    FeedItem fi;
    for (Integer i = 0; i < Trigger.new.size(); i++) {
        fi = Trigger.new[i];
        fiInMap.put(i.format(), fi.Title + ' ' + fi.Body);
    }
    
    if (fiInMap.size() > 0) {
        fiOutMap = mh.checkContent(fiInMap);
    }
    
    for (String k : fiOutMap.keySet()) {
        if (fiOutMap.get(k).startsWith('Error!')) {
            Trigger.new[Integer.valueOf(k)].Body.addError(fiOutMap.get(k));
        }
        if (fiOutMap.get(k).startsWith('Warning!')) {
            Trigger.new[Integer.valueOf(k)].Status = 'PendingReview';
        }
        if (fiOutMap.get(k) == 'OK' && Trigger.old[Integer.valueOf(k)].Status == 'PendingReview') {
            Trigger.new[Integer.valueOf(k)].Status = 'Published';
        }
    }
    
}