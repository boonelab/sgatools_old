package controllers;

import play.*;
import play.mvc.*;

import views.html.*;
import views.html.help.*;

public class Application extends Controller {
  
  public static Result index() {
    return ok(index.render());
  }
  public static Result renderHelpPage() {
	    return ok(helppage.render());
  }
}