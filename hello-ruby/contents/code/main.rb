=begin
/*
Copyright (c) 2008 David Palacio <dpalacio@uninorte.edu.co>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/
=end

require 'plasma_applet'

module PlasmaAppletHelloRuby

class Main < PlasmaScripting::Applet

  #slots 'dataUpdated(QString,Plasma::DataEngine::Data)'

  def initialize(parent, args = nil)
    super
  end

  def init
    resize(600, 400)
  end

  def paintInterface(p, option, rect)
    p.pen = Qt::Color.new 'steelblue'
    p.scale 3, 3
    p.draw_text Qt::RectF.new( rect ), 'Hello Ruby'
  end

  def constraintsEvent(constraints)
  end

end

end
