(function () {
  'use strict';

  angular.module('ledgerDirectives')
    .directive('ldrBubbleEditor', bubbleEditor);

  bubbleEditor.$inject = ['tags', 'tagsHelper', 'money'];

  function bubbleEditor(tags, tagsHelper, money) {
    return {
      restrict: 'A',
      link: linkFn
    };

    ///////////////

    function linkFn(scope, element, attrs) {
      if(attrs.editable != null && !scope.$eval(attrs.editable)) {
        return;
      }

      var editorType = attrs.ldrBubbleEditor || 'default';
      var initialized, showing, shown;
      var editor = null;
      var editorFactories = {
        'default': createDefaultEditor,
        'date': createDateEditor,
        'tags': createTagsEditor
      };

      function buildEditor(resolve) {
        editorFactories[editorType](scope, element, attrs, function (edt) {
          edt.form.keypress(function (e) {
              if (e.keyCode == 27) hidePopover();
            })
            .on('submit', function () {
              var originalValue = getValue(scope, attrs);
              var newValue = edt.getNewValue();
              if (newValue == originalValue) {
                hidePopover(element);
              } else {
                scope.$eval(attrs.submit, {newValue: edt.getNewValue()}).success(function () {
                  hidePopover(element);
                });
              }
            });
          resolve(edt);
        });
      }

      function showPopover() {
        if (!shown && !showing) {
          showing = true;
          buildEditor(function (edt) {
            editor = edt;
            element.popover('show');
          });
        }
      }

      function hidePopover() {
        if (shown) {
          element.popover('hide');
        }
      }

      function evalFinally() {
        if (attrs.finally) {
          scope.$eval(attrs.finally);
          scope.$digest();
        }
      }

      var trigger = function () {
        if (!initialized) {
          initialized = true;
          element.popover({
              trigger: 'manual',
              html: true,
              placement: 'auto top',
              container: 'body',
              content: function () {
                return editor.form;
              }
            })
            .on('shown.bs.popover', function () {
              shown = true;
              showing = false;
            })
            .on('hidden.bs.popover', function () {
              if (!shown) return;
              shown = false
              editor.dispose()
              editor = null;
              evalFinally();
            });
        }
        //Toggle may not work here because of the focusout
        shown ? hidePopover() : showPopover();
      };

      if (attrs.triggerOn) {
        scope.$watch(attrs.triggerOn, function (newValue) {
          if (newValue) trigger();
        });
      } else {
        element.click(trigger);
      }

      scope.$on('$destroy', function () {
        element.popover('destroy');
      });
    }


    function createDefaultEditor(scope, element, attrs, resolve) {
      var input, value = getValue(scope, attrs);
      var form = $('<form>').append(input = $('<input type="text" class="form-control">').val(format(value, attrs))
        .on('focusout', function () {
          element.popover('hide');
        }));
      var shownHandler;
      element.on('shown.bs.popover', shownHandler = function () {
        input.focus();
      });
      resolve({
        form: form,
        dispose: function () {
          form.off();
          element.off('shown.bs.popover', shownHandler);
        },
        getNewValue: function () {
          return input.val();
        }
      });
    }

    function createDateEditor(scope, element, attrs, resolve) {
      var datepicker, input, form = $('<form class="form-inline">')
        .append(datepicker = $('<div class="input-group">')
          .append(input = $('<input type="text" class="form-control" />'))
          .append('<span class="input-group-addon"><span class="glyphicon glyphicon-calendar"></span></span>')
          .datetimepicker()
        )
        .on('dp.show', function () {
          input.focus(); //The dp takes focus when showing. Restoring the focus to avoiding hidding.
        })
        .on('focusout', function () {
          setTimeout(function () {
            if (!input.is(':focus')) element.popover('hide');
          }, 100); //Using such a timeout to let focus to be restored if needed (see db.show handler above)
        });
      datepicker = datepicker.data('DateTimePicker');
      var shownHandler;
      element.on('shown.bs.popover', shownHandler = function () {
        input.focus();
      });
      datepicker.setDate(getValue(scope, attrs));
      resolve({
        form: form,
        dispose: function () {
          form.off();
          element.off('shown.bs.popover', shownHandler);
          datepicker.destroy();
        },
        getNewValue: function () {
          return datepicker.getDate().toDate();
        }
      });
    }

    function createTagsEditor(scope, element, attrs, resolve) {
      var tagsByName = tagsHelper.indexByName(tags.getAll());
      var tagsById = tagsHelper.indexById(tags.getAll());

      var input, form = $('<form class="form-inline" style="width: 200px">')
        .append($('<div class="form-group" style="display: block;">')
          .append(input = $('<input type="text" class="form-control" placeholder="Tags" style="width: 100%">'))
        );
      input.tagsinput({
        confirmKeys: [188],
        tagClass: function (tag) {
          return tagsByName[tag.toLowerCase()] ? 'label label-info' : 'label label-warning';
        }
      });
      form.find('div.bootstrap-tagsinput').css({display: 'block', marginBottom: 0});
      var tagsinput = input.data('tagsinput');
      var actualInput = input.tagsinput('input');
      actualInput.keypress(function (e) {
        //Forcing refresh on enter
        if (e.keyCode == 13) {
          tagsinput.add(actualInput.val());
          actualInput.val('');
          form.trigger('submit');
        }
      }).on('focusout', function () {
        element.popover('hide');
      });
      input.on('change', function () {
        var selectedTagNames = input.tagsinput('items');
        if (selectedTagNames.length) {
          actualInput.removeAttr('placeholder');
        } else {
          actualInput.attr('placeholder', 'Tags');
        }
      });

      //Set initial value
      var tagIds = tagsHelper.bracedStringToArray(getValue(scope, attrs));
      $.each(tagIds, function (index, tagId) {
        input.tagsinput('add', tagsById[tagId].name);
      });

      var shownHandler;
      element.on('shown.bs.popover', shownHandler = function () {
        form.find('input').focus();
      });
      resolve({
        form: form,
        dispose: function () {
          form.off();
          input.off();
          element.off('shown.bs.popover', shownHandler);
          tagsinput.destroy();
        },
        getNewValue: function () {
          var selectedTagNames = input.tagsinput('items');
          var tagIds = [];
          $.each(selectedTagNames, function (index, tagName) {
            var tag = tagsByName[tagName.toLowerCase()];
            if (tag) tagIds.push(tag.tag_id);
          });
          return tagIds;
        }
      });
    }

    function getValue(scope, attrs) {
      return scope.$eval(attrs.value);
    }

    function format(value, attrs) {
      format._formatters = format._formatters || {
          money: money.formatInteger
        };

      if (attrs.format) {
        return format._formatters[attrs.format](value);
      } else {
        return value;
      }
    }
  }
})();