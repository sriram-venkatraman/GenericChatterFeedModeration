trigger FeedCommentTrigger on FeedComment (before insert, before update) {

    ModerationHandler mh = new ModerationHandler();
    Map<String, String> fcInMap = new Map<String, String>();
    Map<String, ModerationHandler.ModerationResponse> fcOutMap;
    
    FeedComment fc;
    for (Integer i = 0; i < Trigger.new.size(); i++) {
        fc = Trigger.new[i];
        fcInMap.put(i.format(), fc.CommentBody);
    }
    
    if (fcInMap.size() > 0) {
        fcOutMap = mh.checkContent(fcInMap);
    }

    for (String k : fcOutMap.keySet()) {
        ModerationHandler.ModerationResponse mr = fcOutMap.get(k);

        if (mr.getStatus().startsWith('Error!')) {
            Trigger.new[Integer.valueOf(k)].CommentBody.addError(mr.getStatus());
        }
        if (mr.getStatus().startsWith('Warning!')) {
            Trigger.new[Integer.valueOf(k)].Status = 'PendingReview';
        }
        if (mr.getStatus().startsWith('Redacted!')) {
            Trigger.new[Integer.valueOf(k)].Status = 'Published';
            Trigger.new[Integer.valueOf(k)].CommentBody = mr.getRedactedContent();
        }
        if (mr.getStatus() == 'OK' && Trigger.old[Integer.valueOf(k)].Status == 'PendingReview') {
            Trigger.new[Integer.valueOf(k)].Status = 'Published';
        }
    }
    
}