

test("----- masterDetail -----", function (check, pass) {

  function yOffset (pixels) {
    return pixels / UIATarget.localTarget().frontMostApp().mainWindow().rect().size.height
  }

  function removeCell(cell) {
    var width = cell.rect().size.width
    logElement(width)
    var x = 46 / width
    cell.tapWithOptions({tapOffset: {x: x, y: 0.5}});
    UIATarget.localTarget().delay( 2 );
    x = (width - 60) / width
    cell.tapWithOptions({tapOffset: {x: x, y: 0.5}});
  }


  UIATarget.localTarget().frontMostApp().mainWindow().tableViews()[0].cells()[2].tap();

  UIATarget.localTarget().frontMostApp().navigationBar().rightButton().tap();
  UIATarget.localTarget().frontMostApp().mainWindow().dragInsideWithOptions({startOffset:{x:0.93, y:yOffset(300)}, endOffset:{x:0.95, y:yOffset(200)}, duration:1.5});
  UIATarget.localTarget().frontMostApp().mainWindow().dragInsideWithOptions({startOffset:{x:0.93, y:yOffset(300)}, endOffset:{x:0.95, y:yOffset(100)}, duration:1.5});

  removeCell(UIATarget.localTarget().frontMostApp().mainWindow().tableViews()[0].cells()[1]);

  UIATarget.localTarget().delay( 2 );

  UIATarget.localTarget().frontMostApp().navigationBar().rightButton().tap();
  UIATarget.localTarget().frontMostApp().mainWindow().tableViews()[0].cells()[1].tap();
  UIATarget.localTarget().frontMostApp().navigationBar().leftButton().tap();

  UIATarget.localTarget().delay( 2 );

  UIATarget.localTarget().frontMostApp().navigationBar().leftButton().tap();

  pass()
});












