
window.scrollOrders = 0

window.slowScrollTo = (position, speed) ->
  scrollTop = $(window).scrollTop()
  distance = Math.abs(position - scrollTop)
  timing = if speed then speed else window.atMost(3000, (distance * 1.5) + 500)
  window.scrollOrders += 1
  
  $('#monitor').html(window.scrollOrders + ': Scrolling from ' + scrollTop + ' to ' + position + "taking " + timing)
  $('html,body').animate({scrollTop: position}, timing)

$ ->

  window.throttledScroll = _.throttle(window.slowScrollTo, 1000, {trailing: false})

  window.nextZone = ->
    scrolltop = $(window).scrollTop();
    for landing in window.landings
      if scrolltop < landing and Math.abs(scrolltop - landing) > 100
        return window.throttledScroll(landing)

  window.previousZone = ->
    scrolltop = $(window).scrollTop();
    for landing in window.landings by -1
      if scrolltop > landing and Math.abs(scrolltop - landing) > 100
        return window.throttledScroll(landing)
        
  $("div").swipe {
    swipeUp: (event, direction, distance, duration, fingerCount) ->
      window.nextZone()
    swipeDown: (event, direction, distance, duration, fingerCount) ->
      window.previousZone()
   }

  $("div").click ->
    window.nextZone()



window.listZones = () ->
  
  for zone in window.scrollZones
    console.log(zone.element[0].id + " - " + zone.start + " - " + zone.property)

window.atMost = (lim, num) ->
  if num > lim 
    return lim;
  else
    return num;

window.atLeast = (lim, num) ->
  if num < lim 
    return lim;
  else
    return num;

flatten = (lim, flat, num) ->
   ## As num decreases toward lim, we want to flatten it to flat.
   ## ie, when opacity gets to be .004, we'll just call it 0.
   ## flatten(.01, 0, .004) == 0
   if (num < lim)
      return flat
   else
      return num




window.scrollZones = []

class window.Zone
  constructor: (@start, @end, @element) ->
    @features = []
    window.scrollZones.push this

  hide: ->
    $(@element.selector + " *").css('visibility', 'hidden')

  show: ->
    $(@element.selector + " *").css('visibility', 'visible')

  addFeature: (start, duration, high, low, property, direction="in", subelement) ->
#    console.log("element: " + @element.selector)

    if subelement
      element = $(subelement.selector, @element.selector)
      #console.log(subelement.selector)
    else
      element = @element
    

    zoneStart = @start
    start = zoneStart + start

    featureFunc = (position) ->
      
      if position < start
      # Feature hasn't start yet; turn it off.
        if direction == "in"      
          value = flatten(low + .01, low, low)
        else
          value = high
      else 
      # We are in the middle of this feature.  Let's execute it.
        distance = position - start
        differential = distance / duration
        # TODO: If only one of "low" or "high" are negative, and the other is positive, we may get weird results.
        if direction == "in" # Increasing value as position increases
          if high < 0  # If high is negative, we need to compare its abs against differential....
            value = 0 - window.atMost(Math.abs(high), differential) # and then take the negative version of the lower.
          else 
            value = window.atMost(high, differential) 
        else # Descreaing value as position increases
          if low < 0
            value = 0 - flatten(Math.abs(low) + .01, Math.abs(low), Math.abs(high) - differential) # Flatten anything within .01 to low.
          else
            value = flatten(low + .01, low, high - differential) 
      element.css(property, value.toFixed(2));
    @features.push(featureFunc)


  addFade: (start=@start, duration=@end, direction="in", subelement) ->
    @addFeature(start, duration, 1, 0, 'opacity', direction, subelement)

  addState: (start, before, after, property, subelement) ->
    if subelement
      element = $(subelement.selector, @element.selector)
      #console.log(subelement.selector)
    else
      element = @element

    zoneStart = @start
    start = zoneStart + start

    stateFunc = (position) ->
      if position > start
        element.css(property, after)
      else
        element.css(property, before)
    @features.push(stateFunc)

  addFreeze: (freezePoint) ->
    buffer = 1000    
    scrolls = buffer - freezePoint
    absTop = buffer + @start
    
    
    @addState(scrolls, "absolute", "fixed", 'position')
    @addState(scrolls, absTop, freezePoint, 'top')



  
window.scrollEm = (position) ->
  #console.log(position)
  for zone in window.scrollZones
    if position >= zone.start and position < zone.end
      zone.show()
      for feature in zone.features
        feature(position)
    else
      zone.hide()     
