trigger FeedCommentTrigger on FeedComment (before insert, before update) {

    ModerationHandler mh = new ModerationHandler();
    Map<String, String> fcInMap = new Map<String, String>();
    Map<String, String> fcOutMap = new Map<String, String>();
    
    FeedComment fc;
    for (Integer i = 0; i < Trigger.new.size(); i++) {
        fc = Trigger.new[i];
        fcInMap.put(i.format(), fc.CommentBody);
    }
    
    if (fcInMap.size() > 0) {
        fcOutMap = mh.checkContent(fcInMap);
    }
    
    for (String k : fcOutMap.keySet()) {
        if (fcOutMap.get(k).startsWith('Error!')) {
            Trigger.new[Integer.valueOf(k)].CommentBody.addError(fcOutMap.get(k));
        }
        if (fcOutMap.get(k).startsWith('Warning!')) {
            Trigger.new[Integer.valueOf(k)].Status = 'PendingReview';
        }
    }
    
}