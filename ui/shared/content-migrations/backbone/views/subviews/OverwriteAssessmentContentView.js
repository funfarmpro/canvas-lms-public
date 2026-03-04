/*
 * Copyright (C) 2023 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import {extend} from '@canvas/backbone/utils'
import Backbone from '@canvas/backbone'
import template from '../../../jst/subviews/OverwriteAssessmentContent.handlebars'

extend(OverwriteAssessmentContentView, Backbone.View)

function OverwriteAssessmentContentView() {
  this.setAttribute = this.setAttribute.bind(this)
  return OverwriteAssessmentContentView.__super__.constructor.apply(this, arguments)
}

OverwriteAssessmentContentView.prototype.template = template

OverwriteAssessmentContentView.prototype.events = {
  'change #overwriteAssessmentContent': 'setAttribute',
  'change #replaceQuestionBankContent': 'setAttribute',
}

OverwriteAssessmentContentView.prototype.setAttribute = function () {
  const settings = this.model.get('settings') || {}
  const overwrite = !!this.$el.find('#overwriteAssessmentContent').is(':checked')
  const $replace = this.$el.find('#replaceQuestionBankContent')
  if (!overwrite) {
    $replace.prop('checked', false)
  }
  $replace.prop('disabled', !overwrite)

  settings.overwrite_quizzes = overwrite
  settings.replace_question_bank_content = overwrite && !!$replace.is(':checked')
  return this.model.set('settings', settings)
}

export default OverwriteAssessmentContentView
